# Shared services for headless server hosts (imported by the hosts/vps/*
# configurations in flake.nix; the desktop/WSL hosts do not get these).
{ config, ... }:
{
  imports = [
    # Self-hosted Tailscale DERP relay (configured per host).
    ./modules/derper.nix

    # Docker Engine + /etc/docker plumbing.
    ./modules/docker.nix

    # Docker Compose project: static index + reverse proxy (tailnet-only).
    ./services/compose
  ];

  # `services.tailscale.enable` lives in os/basic.nix (shared by all hosts).

  services.iperf3.enable = true; # tailnet only, not public
  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [ config.services.iperf3.port ];
    allowedUDPPorts = [ config.services.iperf3.port ];
  };
}
