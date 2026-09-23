# Shared services for headless server hosts (imported by the `vps` host in
# flake.nix; the desktop/WSL hosts do not get these).
{ ... }:
{
  imports = [
    # Self-hosted Tailscale DERP relay (services.ipDerper). Configured per host
    # in hosts/<host>/configuration.nix.
    ./modules/derper.nix
  ];

  # `services.tailscale.enable` lives in os/dev.nix (shared by all hosts).
  # The ipDerper module also pulls it in when `verifyClients` is on.

  # NOTE: no `networking.firewall.trustedInterfaces = [ "tailscale0" ]` here on
  # purpose. The tailnet needs nothing beyond SSH (22, opened by the openssh
  # module) and the DERP port (opened by services.ipDerper), so letting *all*
  # ports on this host bypass the firewall is unnecessary attack surface.
}
