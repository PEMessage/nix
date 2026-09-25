# OpenCanary multi-protocol honeypot, run as a rootless oci-container.
#
# The image is pulled at *build* time from Docker Hub into a fixed-output
# derivation (`dockerTools.pullImage`): it is digest-pinned and travels in the
# system closure via `nix copy`, so the target host never needs registry access
# (docker.io is unreachable from the VPS and the mirrors don't carry it).
#
# It uses host networking so it sees real connections and can bind low ports
# (allowed by net.ipv4.ip_unprivileged_port_start = 0). Ports are opened in the
# firewall only on the public interface, never on tailscale0.
{ config, lib, pkgs, ... }:
let
  cfg = config.services.opencanary;

  image = pkgs.dockerTools.pullImage {
    imageName = "thinkst/opencanary";
    finalImageName = "thinkst/opencanary";
    finalImageTag = "0.9.10";
    imageDigest = "sha256:4e51338e3b6e349652b0604be656d9b8fc1cde2cd40409b2e956f1da3eb673a1";
    sha256 = "sha256-bWZZbjnvWGxwTCe9+36Gj4I7ewep9cLeffFRKvBQleU=";
    os = "linux";
    arch = "amd64";
  };

  conf = pkgs.writeText "opencanary.conf" (builtins.toJSON {
    "device.node_id" = config.networking.hostName;

    "ftp.enabled" = true;
    "ftp.port" = 21;
    "ftp.banner" = "FTP server ready";

    "http.enabled" = true;
    "http.port" = 80;
    "http.banner" = "Apache/2.2.22 (Ubuntu)";
    "http.skin" = "nasLogin";

    "ssh.enabled" = true;
    "ssh.port" = 22;
    "ssh.version" = "SSH-2.0-OpenSSH_5.1p1 Debian-4";

    # Log to stdout (journald) and to a rotating file on the host.
    "logger" = {
      class = "PyLogger";
      kwargs = {
        formatters.plain.format = "%(message)s";
        handlers = {
          console = {
            class = "logging.StreamHandler";
            stream = "ext://sys.stdout";
          };
          file = {
            class = "logging.handlers.RotatingFileHandler";
            filename = "${cfg.dataDir}/opencanary.log";
            maxBytes = 10485760;
            backupCount = 5;
          };
        };
      };
    };
  });
in
{
  options.services.opencanary = {
    enable = lib.mkEnableOption "OpenCanary honeypot (rootless podman container)";

    user = lib.mkOption {
      type = lib.types.str;
      default = "pem";
      description = "User to run the (rootless) container as.";
    };

    publicInterface = lib.mkOption {
      type = lib.types.str;
      default = "enp1s0";
      description = ''
        Interface the honeypot ports are opened on. Deliberately NOT opened on
        tailscale0, so tailnet traffic cannot hit the honeypot.
      '';
    };

    ports = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [
        21
        22
        80
      ];
      description = "TCP ports the honeypot listens on (matched by its modules).";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/opencanary";
      description = "Host directory for persistent honeypot data (logs).";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.opencanary = {
      image = "thinkst/opencanary:0.9.10";
      imageFile = image;
      podman.user = cfg.user;
      # `--dev` runs opencanaryd in the foreground (twistd -noy); `--start`
      # would daemonize and the container's PID 1 would exit immediately.
      cmd = [ "--dev" ];
      extraOptions = [ "--network=host" ];
      volumes = [
        "${conf}:/etc/opencanaryd/opencanary.conf:ro"
        "${cfg.dataDir}:${cfg.dataDir}"
      ];
      autoStart = true;
    };

    # Log directory, writable by the (rootless) container user.
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.user} -"
    ];

    networking.firewall.interfaces.${cfg.publicInterface}.allowedTCPPorts = cfg.ports;
  };
}
