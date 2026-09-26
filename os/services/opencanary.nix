# OpenCanary multi-protocol honeypot, as a home-manager Podman service
# (`services.opencanary`). Imported by os/server.nix; runs rootless as a
# user-level Podman Quadlet with host networking so it can bind low ports.
{ config, lib, pkgs, osConfig, ... }:
{
  options.services.opencanary = {
    enable = lib.mkEnableOption "OpenCanary honeypot (rootless podman Quadlet)";

    # No defaults: the caller (os/server.nix) declares them.
    stateDir = lib.mkOption {
      type = lib.types.str;
      description = "Honeypot state directory (absolute path).";
      example = "/home/pem/server/opencanary";
    };

    ports = lib.mkOption {
      type = lib.types.attrsOf lib.types.port;
      description = "Port per enabled honeypot module: { ftp, ssh, http }.";
    };
  };

  config = lib.mkIf config.services.opencanary.enable (
    let
      cfg = config.services.opencanary;

      # Pulled at build time: digest-pinned, shipped in the closure via
      # `nix copy`, then loaded by a `.image` Quadlet's `docker-archive:`
      # transport. The host never needs registry access (docker.io is
      # unreachable from the VPS).
      image = pkgs.dockerTools.pullImage {
        imageName = "thinkst/opencanary";
        finalImageName = "thinkst/opencanary";
        finalImageTag = "0.9.10";
        imageDigest = "sha256:4e51338e3b6e349652b0604be656d9b8fc1cde2cd40409b2e956f1da3eb673a1";
        sha256 = "sha256-bWZZbjnvWGxwTCe9+36Gj4I7ewep9cLeffFRKvBQleU=";
        os = "linux";
        arch = "amd64";
      };

      # `.image` Quadlet needs an explicit tag to name the `docker-archive:` import.
      tag = "thinkst/opencanary:0.9.10";

      conf = pkgs.writeText "opencanary.conf" (builtins.toJSON {
        "device.node_id" = osConfig.networking.hostName;

        "ftp.enabled" = true;
        "ftp.port" = cfg.ports.ftp;
        "ftp.banner" = "FTP server ready";

        "http.enabled" = true;
        "http.port" = cfg.ports.http;
        "http.banner" = "Apache/2.2.22 (Ubuntu)";
        "http.skin" = "nasLogin";

        "ssh.enabled" = true;
        "ssh.port" = cfg.ports.ssh;
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
                filename = "${cfg.stateDir}/opencanary.log";
                maxBytes = 10485760;
                backupCount = 5;
              };
            };
          };
        };
      });
    in
    {
      services.podman = {
        enable = true;

        images.opencanary = {
          image = "docker-archive:${image}";
          inherit tag;
        };

        containers.opencanary = {
          description = "OpenCanary honeypot";
          image = "opencanary.image";
          # `--dev` runs in the foreground; `--start` would daemonize and PID 1
          # would exit immediately.
          exec = "--dev";
          network = "host";
          volumes = [
            "${conf}:/etc/opencanaryd/opencanary.conf:ro"
            "${cfg.stateDir}:${cfg.stateDir}"
          ];
        };
      };

      # State dir must exist before the container starts.
      home.activation.opencanary-state-dir = lib.hm.dag.entryBefore [ "reloadSystemd" ] ''
        run mkdir -p ${lib.escapeShellArg cfg.stateDir}
      '';
    }
  );
}
