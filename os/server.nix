# Shared services for headless server hosts (imported by the `vps` host in
# flake.nix; the desktop/WSL hosts do not get these).
{ config, ... }:
let
  # Rootless honeypot service (implemented in os/services/opencanary.nix). As a
  # home-manager module it can read `config.home.*`, so it computes the full
  # state path itself instead of passing a partial path down.
  homeModule =
    { config, lib, ... }:
    {
      imports = [ ./services/opencanary.nix ];
      services.opencanary = {
        enable = true;
        stateDir = toString (lib.path.append (/. + config.home.homeDirectory) "server/opencanary");
        ports = {
          ftp = 21;
          ssh = 22;
          http = 8080;
        };
      };
    };
in
{
  imports = [
    # Self-hosted Tailscale DERP relay (configured per host).
    ./modules/derper.nix

    # Podman + /etc/containers plumbing.
    ./modules/podman.nix
  ];

  home-manager.sharedModules = [ homeModule ];

  # `services.tailscale.enable` lives in os/basic.nix (shared by all hosts).

  services.iperf3.enable = true; # tailnet only, not public
  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [ config.services.iperf3.port ];
    allowedUDPPorts = [ config.services.iperf3.port ];
  };

  # Let rootless containers bind low ports.
  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 0;

  # Honeypot ports (match homeModule above), public interface only.
  networking.firewall.interfaces.enp1s0.allowedTCPPorts = [
    21
    22
    8080
  ];
}
