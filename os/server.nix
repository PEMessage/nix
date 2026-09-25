# Shared services for headless server hosts (imported by the `vps` host in
# flake.nix; the desktop/WSL hosts do not get these).
{ config, ... }:
{
  imports = [
    # Self-hosted Tailscale DERP relay (services.ipDerper). Configured per host
    # in hosts/<host>/configuration.nix.
    ./modules/derper.nix

    # Shared Podman + /etc/containers setup for declarative containers.
    ./modules/podman.nix

    # Declarative containerized services.
    ./services/opencanary.nix
  ];

  # `services.tailscale.enable` lives in os/basic.nix (shared by all hosts).
  # The ipDerper module also pulls it in when `verifyClients` is on.

  # NOTE: no `networking.firewall.trustedInterfaces = [ "tailscale0" ]` here on
  # purpose. The tailnet needs nothing beyond SSH (22, opened by the openssh
  # module), the DERP port (services.ipDerper) and iperf3, so letting *all*
  # ports on this host bypass the firewall is unnecessary attack surface.

  # iperf3 throughput test server, reachable over the tailnet only (not public).
  services.iperf3.enable = true;

  # OpenCanary honeypot (see ./services/opencanary.nix). Real SSH lives on 18622;
  # its ports are opened only on the public interface, never on tailscale0.
  services.opencanary.enable = true;

  # Let unprivileged (rootless) containers bind low ports, e.g. a honeypot on
  # :22 or :80. Required because containers run with `podman.user` (rootless).
  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 0;

  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [ config.services.iperf3.port ];
    allowedUDPPorts = [ config.services.iperf3.port ];
  };
}
