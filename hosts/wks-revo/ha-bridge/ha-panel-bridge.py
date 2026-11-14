#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "ha-mqtt-discoverable>=0.24.2,<0.25",
#   "paho-mqtt>=2.1,<3",
#   "pydantic-settings>=2.12,<3",
#   "tomli-w>=1.2,<2",
#   "click>=8.2,<9",
# ]
# ///
"""Bridge a DDC/CI panel to Home Assistant over MQTT discovery.

Home Assistant drives the Windows PC (PEMPRO) through HASS.Agent: MQTT discovery
plus one command topic per button. This does the same for the local panel,
except there is no agent daemon to talk to -- `panelctl` already owns the DDC bus
(see ../panelctl/panelctl), so the bridge is only an MQTT <-> panelctl translator.

    ha-panel-bridge init     # ask for/replace the broker settings, verify, save
    ha-panel-bridge serve    # what the systemd user unit runs
    ha-panel-bridge status   # what HA would see, without touching MQTT

Settings come from ~/.config/ha-bridge/config.toml, then HA_BRIDGE_* environment
variables, then anything given on the command line. The file is 0600 and never
enters the Nix store.

The node name defaults to the hostname, so copying the unit to another machine
yields a separate HA device instead of a collision. Renaming a host leaves the
old retained discovery behind: `status` prints the topics, `mosquitto_pub -r -n
-t <topic>` clears them.

The PEP 723 block above is for running it straight from the checkout:

    uv run hosts/wks-revo/ha-bridge/ha-panel-bridge.py status

The systemd unit does not use uv: nix builds an offline wrapper from nixpkgs, so
keep the dependency list here in sync with the `runtimeInputs` in default.nix.
"""

from __future__ import annotations

import getpass
import logging
import os
import re
import shutil
import signal
import socket
import subprocess
import sys
import threading
from dataclasses import dataclass
from enum import StrEnum
from pathlib import Path
from typing import Any, Literal

import click
import paho.mqtt.client as mqtt
import tomli_w
from ha_mqtt_discoverable import Settings as HaSettings
from ha_mqtt_discoverable.sensors import Button, ButtonInfo, Switch, SwitchInfo
from ha_mqtt_discoverable.utils import clean_string
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict, TomlConfigSettingsSource

log = logging.getLogger("ha-panel-bridge")

class ClapHelp(click.HelpFormatter):
    """Click's borderless layout, coloured like clap: bold headings, cyan switches.

    click strips ANSI when the stream is not a TTY, so piping stays clean.
    """

    _SWITCH = re.compile(r"(?<![\w-])(--?[A-Za-z0-9][\w-]*)")

    def write_heading(self, heading: str) -> None:
        super().write_heading(click.style(heading, bold=True))

    def write_usage(self, prog: str, args: str = "", prefix: str | None = None) -> None:
        super().write_usage(
            click.style(prog, bold=True),
            click.style(args, fg="cyan"),
            prefix=click.style(prefix or "Usage: ", bold=True),
        )

    def write_dl(self, rows, col_max: int = 30, col_spacing: int = 2) -> None:
        def colour(term: str) -> str:
            return self._SWITCH.sub(lambda m: click.style(m.group(1), fg="cyan"), term)

        # term_len() strips ANSI, so the column padding still lines up.
        super().write_dl([(colour(term), text) for term, text in rows], col_max, col_spacing)


class ClapContext(click.Context):
    formatter_class = ClapHelp


class ClapCommand(click.Command):
    context_class = ClapContext


class ClapGroup(click.Group):
    context_class = ClapContext
    command_class = ClapCommand


def broker_options(*extra):
    """Attach the shared broker flags, in the order they should appear in --help.

    click renders options in reverse decoration order, so apply them backwards.
    """
    options = [
        click.option("--host", metavar="HOST", help="MQTT broker host"),
        click.option("--port", metavar="PORT", type=int, help="MQTT broker port"),
        click.option("--username", metavar="USER", help="MQTT username"),
        *extra,
        click.option("--discovery-prefix", metavar="PREFIX", help="discovery prefix"),
        click.option("--node", metavar="NODE", help="default: hostname"),
    ]

    def decorate(command):
        for option in reversed(options):
            command = option(command)
        return command

    return decorate

CONFIG_PATH = Path.home() / ".config" / "ha-bridge" / "config.toml"

# Retained discovery is the only thing HA needs, but EMQX keeps retained
# messages in a container-local data dir, so re-advertise now and then.
REASSERT_INTERVAL = 900

# `panelctl power on` polls for WAKE_TRIES; `power off` verifies with OFF_TRIES.
PANELCTL_TIMEOUT = 90


def fail(message: str) -> click.ClickException:
    return click.ClickException(message)


# -- settings --------------------------------------------------------------


class Config(BaseSettings):
    """Broker settings, layered: command line > HA_BRIDGE_* env > config.toml."""

    model_config = SettingsConfigDict(
        toml_file=CONFIG_PATH, env_prefix="HA_BRIDGE_", extra="forbid"
    )

    @classmethod
    def settings_customise_sources(
        cls, settings_cls, init_settings, env_settings, dotenv_settings, file_secret_settings
    ):
        # pydantic-settings does not read `toml_file` on its own.
        return init_settings, env_settings, TomlConfigSettingsSource(settings_cls)

    node: str = Field(default_factory=lambda: socket.gethostname().split(".")[0])
    host: str = "127.0.0.1"
    port: int = 1883
    username: str = ""
    password: str = ""
    discovery_prefix: str = "homeassistant"

    def with_overrides(self, **overrides: Any) -> Config:
        """CLI flags that were not passed are None; keep the lower layers."""
        given = {key: value for key, value in overrides.items() if value is not None}
        return self.model_copy(update=given) if given else self

    @property
    def slug(self) -> str:
        """Topic-safe node name: hyphens stay, everything else becomes one."""
        return re.sub(r"[^A-Za-z0-9_-]", "-", self.node).lower()

    @property
    def object_id(self) -> str:
        """HA entity/unique ids only accept [a-z0-9_]."""
        return re.sub(r"[^a-z0-9]+", "_", self.slug).strip("_")

    def save(self) -> None:
        CONFIG_PATH.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
        # Write a fresh file so an existing 0644 cannot survive a chmod.
        tmp = CONFIG_PATH.with_suffix(".tmp")
        tmp.write_text(
            "# Written by `ha-panel-bridge init`: holds the MQTT password, so it is\n"
            "# 0600 and must never be committed or picked up by chezmoi.\n"
            + tomli_w.dumps(self.model_dump())
        )
        tmp.chmod(0o600)
        tmp.replace(CONFIG_PATH)


def resolve(
    host: str | None = None,
    port: int | None = None,
    username: str | None = None,
    node: str | None = None,
    discovery_prefix: str | None = None,
) -> Config:
    return Config().with_overrides(
        host=host, port=port, username=username, node=node, discovery_prefix=discovery_prefix
    )


def check_broker(config: Config) -> str | None:
    """Connect once; None on success, otherwise a human-readable reason."""
    connected = threading.Event()
    reason: list[str] = []

    def on_connect(client, userdata, flags, reason_code, properties=None):
        if reason_code == 0:
            connected.set()
        else:
            reason.append(str(reason_code))

    client = mqtt.Client(
        mqtt.CallbackAPIVersion.VERSION2, client_id=f"ha-panel-bridge-init-{os.getpid()}"
    )
    client.on_connect = on_connect
    client.username_pw_set(config.username, config.password)
    try:
        client.connect(config.host, config.port, keepalive=10)
    except OSError as exc:
        return f"{config.host}:{config.port}: {exc}"
    client.loop_start()
    try:
        if not connected.wait(8):
            return f"{config.host}:{config.port}: no CONNACK in 8s" + (
                f" ({reason[0]})" if reason else ""
            )
    finally:
        client.loop_stop()
        client.disconnect()
    return None


# -- panel -----------------------------------------------------------------


class PanelState(StrEnum):
    ON = "on"
    STANDBY = "standby"
    SUSPEND = "suspend"
    OFF = "off"
    UNKNOWN = "unknown"

    @classmethod
    def read(cls) -> PanelState:
        out = panelctl("status")
        if out is None:
            return cls.UNKNOWN
        try:
            return cls(out.strip().lower())
        except ValueError:
            return cls.UNKNOWN

    @property
    def as_switch(self) -> bool | None:
        """True/False for HA, or None when the AUX channel did not answer."""
        return None if self is PanelState.UNKNOWN else self is PanelState.ON


def panelctl(*argv: str) -> str | None:
    exe = shutil.which("panelctl")
    if exe is None:
        raise fail("panelctl is not in PATH")
    try:
        proc = subprocess.run(
            [exe, *argv], capture_output=True, text=True, timeout=PANELCTL_TIMEOUT, check=False
        )
    except subprocess.TimeoutExpired:
        log.error("panelctl %s: timed out", " ".join(argv))
        return None
    if proc.returncode != 0:
        log.error("panelctl %s: rc=%s %s", " ".join(argv), proc.returncode, proc.stderr.strip())
        return None
    return proc.stdout.strip()


# -- what HA sees ----------------------------------------------------------
# The whole HA surface is this table: one row per entity, mapping the payload HA
# sends to the panelctl invocation it triggers.


@dataclass(frozen=True)
class EntitySpec:
    kind: Literal["switch", "button"]
    name: str
    display: str
    icon: str
    commands: dict[str, tuple[str, ...]]


ENTITIES: tuple[EntitySpec, ...] = (
    EntitySpec(
        "switch",
        "panel",
        "Monitor",
        "mdi:monitor",
        {"ON": ("power", "on"), "OFF": ("power", "off")},
    ),
    EntitySpec(
        "button",
        "panel-toggle",
        "Monitor toggle",
        "mdi:monitor-dashboard",
        {"PRESS": ("power", "toggle")},
    ),
)

STATE_ENTITY = "panel"
"""Entity that mirrors panelctl status back to HA."""


def config_topic(config: Config, spec: EntitySpec) -> str:
    node = clean_string(config.slug)
    return f"{config.discovery_prefix}/{spec.kind}/{node}/{clean_string(spec.name)}/config"


def make_entity(config: Config, spec: EntitySpec, on_command) -> Switch | Button:
    """Build one discovery entity; the device is named after the host."""
    common = dict(
        name=spec.name,
        display_name=spec.display,
        icon=spec.icon,
        unique_id=f"{config.object_id}-{spec.name}",
        object_id=f"{config.object_id}_{spec.name.replace('-', '_')}",
        device={
            "identifiers": [f"ha-bridge-{config.object_id}"],
            "name": config.slug,
            "manufacturer": "nix (ha-bridge)",
            "model": "DDC/CI panel",
        },
    )
    settings = HaSettings(
        mqtt=HaSettings.MQTT(
            host=config.host,
            port=config.port,
            username=config.username,
            password=config.password,
            discovery_prefix=config.discovery_prefix,
            state_prefix="panel-bridge",
            client_name=f"ha-panel-bridge-{config.slug}-{spec.name}",
        ),
        # Availability comes from the MQTT last will: a dead bridge shows up as
        # unavailable instead of silently doing nothing.
        entity=SwitchInfo(**common, retain=True) if spec.kind == "switch" else ButtonInfo(**common),
        manual_availability=True,
    )
    return Switch(settings, on_command) if spec.kind == "switch" else Button(settings, on_command)


class Bridge:
    def __init__(self, config: Config) -> None:
        self.config = config
        self.stopping = threading.Event()
        self.entities: dict[str, Switch | Button] = {
            spec.name: make_entity(config, spec, self._on_command(spec)) for spec in ENTITIES
        }

    # -- HA -> panel -------------------------------------------------------

    def _on_command(self, spec: EntitySpec):
        def handler(client: mqtt.Client, userdata: Any, message: mqtt.MQTTMessage) -> None:
            argv = spec.commands.get(message.payload.decode(errors="replace"))
            if argv is None:
                log.warning("ignoring %s on %s", message.payload, message.topic)
                return
            threading.Thread(target=self._apply, args=(argv,), daemon=True).start()

        return handler

    def _apply(self, argv: tuple[str, ...]) -> None:
        log.info("panelctl %s", " ".join(argv))
        panelctl(*argv)
        self.publish_state()

    # -- bridge -> HA ------------------------------------------------------

    def publish_state(self) -> None:
        switch = self.entities[STATE_ENTITY]
        state = PanelState.read().as_switch
        if state is None:
            log.warning("panel state unknown, leaving the last state in place")
        elif state:
            switch.on()
        else:
            switch.off()

    def set_available(self, online: bool) -> None:
        payload = "online" if online else "offline"
        for entity in self.entities.values():
            # The library publishes manual availability unretained; HA that
            # restarts later still has to find it.
            entity.mqtt_client.publish(entity.availability_topic, payload, retain=True)

    # -- lifecycle ---------------------------------------------------------

    def run(self) -> None:
        for spec in ENTITIES:
            entity = self.entities[spec.name]
            # The library advertises lazily on the first state update, which a
            # button never has: publish every config up front instead.
            entity.write_config()
            log.info("%-14s %s", spec.display, entity.config_topic)

        self.set_available(True)
        # A status read can take half a minute on a bad AUX day; never block the
        # unit's start-up on it.
        threading.Thread(target=self.publish_state, daemon=True).start()
        while not self.stopping.wait(REASSERT_INTERVAL):
            log.debug("re-announcing discovery")
            for entity in self.entities.values():
                entity.write_config()
            self.set_available(True)
            self.publish_state()

    def shutdown(self) -> None:
        self.stopping.set()
        self.set_available(False)


# -- CLI -------------------------------------------------------------------


def ask(label: str, current: Any) -> str:
    """Prompt only on a TTY, so the command stays scriptable."""
    if not sys.stdin.isatty():
        return str(current)
    shown = f" [{current}]" if current not in ("", None) else ""
    try:
        return input(f"{label}{shown}: ").strip() or str(current)
    except EOFError:
        raise fail("no input, aborted") from None


@click.group(cls=ClapGroup, context_settings={"help_option_names": ["-h", "--help"]},
             no_args_is_help=True)
@click.option("-v", "--verbose", is_flag=True, help="debug logging")
def app(verbose: bool) -> None:
    """Bridge a DDC/CI panel to Home Assistant over MQTT discovery."""
    logging.basicConfig(
        level=logging.DEBUG if verbose else logging.INFO, format="%(levelname)s %(message)s"
    )
    logging.getLogger("ha_mqtt_discoverable").setLevel(logging.WARNING)


@app.command()
@broker_options(
    click.option("--password", metavar="PASSWORD", help="omit for a silent prompt")
)
def init(host, port, username, password, discovery_prefix, node) -> None:
    """Ask for the broker connection, verify it, and save it."""
    config = resolve(host, port, username, node, discovery_prefix)
    config = config.with_overrides(
        host=ask("MQTT broker host", config.host),
        port=int(ask("MQTT broker port", config.port)),
        username=ask("MQTT username", config.username),
        discovery_prefix=ask("Discovery prefix", config.discovery_prefix),
    )

    if password is not None:
        config = config.with_overrides(password=password)
    elif sys.stdin.isatty():
        config = config.with_overrides(
            password=getpass.getpass("MQTT password: ") or config.password
        )
    if not config.password:
        raise click.UsageError("--password is required when stdin is not a TTY")

    log.info("checking %s:%s as %r ...", config.host, config.port, config.username)
    if failure := check_broker(config):
        raise fail(f"broker rejected the connection: {failure}")

    config.save()
    log.info("wrote %s (0600)", CONFIG_PATH)
    for spec in ENTITIES:
        log.info("  %s", config_topic(config, spec))
    log.info("next: systemctl --user restart ha-panel-bridge")


@app.command()
@broker_options()
def serve(host, port, username, discovery_prefix, node) -> None:
    """Run the bridge (this is what the systemd user unit starts)."""
    bridge = Bridge(resolve(host, port, username, node, discovery_prefix))

    def on_signal(signum, frame):
        log.info("signal %s, going offline", signum)
        bridge.shutdown()
        raise SystemExit(0)

    signal.signal(signal.SIGTERM, on_signal)
    signal.signal(signal.SIGINT, on_signal)
    bridge.run()


@app.command()
@broker_options()
def status(host, port, username, discovery_prefix, node) -> None:
    """Print the HA-facing topics and the current panel state."""
    config = resolve(host, port, username, node, discovery_prefix)
    click.echo(f"node:    {config.slug}")
    click.echo(f"broker:  {config.host}:{config.port} as {config.username}")
    for spec in ENTITIES:
        click.echo(f"{spec.display:16} {config_topic(config, spec)}")
    click.echo(f"panel:   {PanelState.read().value}")


if __name__ == "__main__":
    # The unit execs `python3 /nix/store/…-ha-panel-bridge.py`, so without an
    # explicit prog_name click would print that path in --help.
    app(prog_name="ha-panel-bridge")
