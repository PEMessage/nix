# Bridge the local DDC panel to Home Assistant over MQTT discovery.
#
# The Windows PC (PEMPRO) is driven by HASS.Agent, which publishes
# `homeassistant/{component}/PEMPRO/...` plus a retained availability topic and
# subscribes to the matching command topics. This does the same for the local
# panel, except there is no agent daemon to talk to: `panelctl` already owns the
# DDC bus, so the bridge is only an MQTT <-> panelctl translator. Discovery
# means HA needs no YAML for it.
#
# `ha-panel-bridge init` owns the broker credentials: they go to
# ~/.config/ha-bridge/config.toml (0600), never into the store.
#
# It is a **user** service on purpose, for two reasons:
#   * panelctl serialises DDC writes with a flock in $XDG_RUNTIME_DIR. A user
#     unit inherits XDG_RUNTIME_DIR=/run/user/1000, so it shares that lock with
#     the DMS widget and a terminal `panelctl` call. A system unit would fall
#     back to /tmp and could race them on the bus.
#   * linger is already enabled for this user, so the unit starts at boot and
#     keeps running with nobody logged in.
#
# The device name in HA comes from the hostname at runtime, not from this file:
# the aspect is host-scoped only because it needs the panelctl aspect next to
# it, and a copy on another host must not collide in the broker.
{ config, ... }:
let
  fp = config;

  # flake-parts modules get no `pkgs`, so bind the derivation per module
  # system; both halves resolve to the same store path.
  mkBridge =
    pkgs:
    pkgs.writeShellApplication {
      name = "ha-panel-bridge";
      runtimeInputs = [
        (pkgs.python3.withPackages (
          ps: with ps; [
            click
            ha-mqtt-discoverable
            paho-mqtt
            pydantic-settings
            tomli-w
          ]
        ))
      ];
      # The script carries a PEP 723 block so `uv run ha-panel-bridge.py` works
      # from a checkout; keep its dependency list in sync with runtimeInputs.
      #
      # panelctl comes from environment.systemPackages (the panelctl aspect);
      # the user manager's PATH already contains /run/current-system/sw/bin.
      text = ''
        exec python3 ${./ha-panel-bridge.py} "$@"
      '';
    };
in
{
  flake.aspects.ha-bridge = {
    nixos = _: {
      home-manager.sharedModules = [ fp.flake.modules.homeManager.ha-bridge ];
    };

    homeManager =
      { pkgs, ... }:
      {
        # Also on PATH so `ha-panel-bridge init` / `status` can be run by hand.
        home.packages = [ (mkBridge pkgs) ];

        systemd.user.services.ha-panel-bridge = {
          Unit.Description = "Home Assistant bridge for the local DDC panel";
          Service = {
            ExecStart = "${mkBridge pkgs}/bin/ha-panel-bridge serve";
            Restart = "always";
            RestartSec = 5;
          };
          Install.WantedBy = [ "default.target" ];
        };
      };
  };
}
