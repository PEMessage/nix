# Shared services for headless server hosts (imported by the `vps` host in
# flake.nix; the desktop/WSL hosts do not get these).
{ config, ... }:
{
  imports = [
    # Self-hosted Tailscale DERP relay (services.ipDerper). Configured per host
    # in hosts/<host>/configuration.nix.
    ./modules/derper.nix
  ];

  # `services.tailscale.enable` lives in os/basic.nix (shared by all hosts).
  # The ipDerper module also pulls it in when `verifyClients` is on.

  # NOTE: no `networking.firewall.trustedInterfaces = [ "tailscale0" ]` here on
  # purpose. The tailnet needs nothing beyond SSH (22, opened by the openssh
  # module), the DERP port (services.ipDerper) and iperf3, so letting *all*
  # ports on this host bypass the firewall is unnecessary attack surface.

  # iperf3 throughput test server, reachable over the tailnet only (not public).
  services.iperf3.enable = true;

  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [ config.services.iperf3.port ];
    allowedUDPPorts = [ config.services.iperf3.port ];
  };
}
