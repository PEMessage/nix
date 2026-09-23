# Self-hosted Tailscale DERP relay reachable by a bare public IP (no domain).
#
# Tailscale >= 1.98's `derper` self-signs an IP-SAN certificate when
# `-hostname` is an IP, so a plain IP works. Clients pin that certificate in
# the tailnet ACL `derpMap` via `CertName` (printed in the journal on first
# start) or, less safely, `InsecureForTests: true`.
#
# The public address is either given literally (`host`) or read at runtime from
# a file (`hostFile`), so it can stay out of git and be injected at deploy time
# (e.g. nixos-anywhere `--extra-files ./secrets/<host>`). Exactly one of the two
# must be set; `hostFile` is read via systemd `LoadCredential`, so the file can
# stay root-only.
#
# Two protocols, each with a public port (what peers dial) and a listen port
# (what derper binds locally; behind NAT these usually differ):
#   derp = { publicPort = <DERPPort>; listenPort = <-a>; };            # TLS/TCP
#   stun = { publicPort = <STUNPort>; listenPort = <-stun-port>; };    # UDP
#
# Example — host behind NAT where the provider maps
# public 1.2.3.4:443/TCP -> local :10443 and 1.2.3.4:3478/UDP -> local :3478:
#
#   services.ipDerper = {
#     enable = true;
#     hostFile = "/var/lib/nixos-secrets/derper-host";  # contains the public IP
#     derp = { publicPort = 443;  listenPort = 10443; };
#     stun = { publicPort = 3478; listenPort = 3478; };  # optional; defaults to derp
#   };
#
# If your NAT maps a single port for both protocols, set only `derp`; `stun`
# falls back to the same numbers.
#
# Then in the tailnet ACL:
#
#   "derpMap": { "Regions": { "900": {
#     "RegionID": 900, "RegionCode": "vps", "RegionName": "vps",
#     "Nodes": [{
#       "Name": "900a", "RegionID": 900,
#       "HostName": "1.2.3.4", "DERPPort": 443, "STUNPort": 3478,
#       "CertName": "sha256-raw:<hex from: journalctl -u tailscale-derper>"
#     }]
#   } } }
{ config, lib, pkgs, ... }:
let
  cfg = config.services.ipDerper;

  derper = lib.getExe' pkgs.tailscale.derper "derper";

  # derper runs STUN by default, so explicitly disable it (`-stun=false`)
  # when `stun.enable` is false.
  stunArgs =
    if cfg.stun.enable then
      [
        "-stun-port"
        (toString cfg.stun.listenPort)
      ]
    else
      [ "-stun=false" ];

  args = [
    "-a"
    ":${toString cfg.derp.listenPort}"
    "-c"
    "/var/lib/derper/derper.key"
    "-certmode"
    "manual"
    "-certdir"
    "/var/lib/derper/certs"
    "-http-port"
    "-1"
  ]
  ++ stunArgs
  ++ lib.optional cfg.verifyClients "-verify-clients";

  # `-hostname` value: literal, or read from a systemd credential at start.
  hostArg =
    if cfg.hostFile != null then
      ''"$(cat "$CREDENTIALS_DIRECTORY/derper-host")"''
    else
      lib.escapeShellArg cfg.host;

  start = pkgs.writeShellScript "tailscale-derper-start" ''
    set -euo pipefail
    exec ${derper} ${lib.escapeShellArgs args} -hostname ${hostArg}
  '';
in
{
  options.services.ipDerper = {
    enable = lib.mkEnableOption "IP-only Tailscale DERP relay (self-signed cert)";

    host = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "1.2.3.4";
      description = ''
        Public IP (or hostname) that tailnet peers dial. Used as derper's TLS
        `-hostname` (a bare IP makes it self-sign an IP-SAN certificate) and as
        the `HostName` of the node in the tailnet ACL `derpMap`.
        Mutually exclusive with {option}`services.ipDerper.hostFile`.
      '';
    };

    hostFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/var/lib/nixos-secrets/derper-host";
      description = ''
        Path to a file on the target system containing the public IP (or
        hostname), read at service start via systemd `LoadCredential`. Use this
        to keep the address out of git. Mutually exclusive with
        {option}`services.ipDerper.host`.
      '';
    };

    derp = {
      publicPort = lib.mkOption {
        type = lib.types.port;
        example = 443;
        description = ''
          Public port that peers dial for DERP (the `DERPPort` in the derpMap).
          Behind NAT this usually differs from
          {option}`services.ipDerper.derp.listenPort`.
        '';
      };

      listenPort = lib.mkOption {
        type = lib.types.port;
        default = cfg.derp.publicPort;
        defaultText = lib.literalExpression "config.services.ipDerper.derp.publicPort";
        example = 10443;
        description = "Local TCP port derper binds and listens on (`-a`).";
      };
    };

    stun = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Run the STUN server (`-stun`). Disable it if the NAT cannot forward a
          UDP port.
        '';
      };

      publicPort = lib.mkOption {
        type = lib.types.port;
        default = cfg.derp.publicPort;
        defaultText = lib.literalExpression "config.services.ipDerper.derp.publicPort";
        example = 3478;
        description = ''
          Public UDP port that peers use for STUN (the `STUNPort` in the
          derpMap). Defaults to {option}`services.ipDerper.derp.publicPort`
          (one NAT port for both protocols); set it to 3478 for the usual split.
        '';
      };

      listenPort = lib.mkOption {
        type = lib.types.port;
        default = cfg.derp.listenPort;
        defaultText = lib.literalExpression "config.services.ipDerper.derp.listenPort";
        example = 3478;
        description = "Local UDP port for the STUN server (`-stun-port`).";
      };
    };

    verifyClients = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Only allow nodes in the local tailnet to use this relay
        (`-verify-clients`). Requires this host to be logged in (`tailscale up`).
      '';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open the local listen ports in the NixOS firewall.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = (cfg.host != null) != (cfg.hostFile != null);
        message = "services.ipDerper: set exactly one of `host` or `hostFile`.";
      }
    ];

    # -verify-clients checks peers against the local tailscaled.
    services.tailscale.enable = lib.mkIf cfg.verifyClients true;

    systemd.services.tailscale-derper = {
      description = "Tailscale DERP relay (IP-only, self-signed)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "tailscaled.service" ];
      wants = [ "network-online.target" "tailscaled.service" ];
      serviceConfig = {
        ExecStart = "${start}";
        LoadCredential =
          lib.optional (cfg.hostFile != null) "derper-host:${cfg.hostFile}";
        DynamicUser = true;
        StateDirectory = "derper";
        Restart = "always";
        RestartSec = "5sec";
        Type = "simple";

        # Same sandboxing as nixos/modules/services/networking/tailscale-derper.nix.
        CapabilityBoundingSet = [ "" ];
        DeviceAllow = null;
        LockPersonality = true;
        NoNewPrivileges = true;
        MemoryDenyWriteExecute = true;
        PrivateDevices = true;
        PrivateUsers = true;
        ProcSubset = "pid";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [ "@system-service" ];
      };
    };

    networking.firewall.allowedTCPPorts =
      lib.optional cfg.openFirewall cfg.derp.listenPort;
    networking.firewall.allowedUDPPorts =
      lib.optional (cfg.openFirewall && cfg.stun.enable) cfg.stun.listenPort;
  };
}
