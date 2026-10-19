# Extras for headless server hosts; imported by the `server` profile only, so a
# workstation never pays for them.
#
# Mirrors the parts of v1's os/server.nix that have something to attach to in
# main. v1 also pulled in derper / docker / services/compose, none of which are
# ported yet.
{ ... }:
{
  flake.aspects.server-tools = {
    nixos =
      { config, lib, pkgs, ... }:
      {
        # Servers stay on bash: they are driven over ssh and the only
        # interactive shell use is recovery, so skip the zsh/completion
        # machinery. mkForce beats the plain zsh value from the `shell` aspect,
        # which already expects a server to override it this way.
        users.defaultUserShell = lib.mkForce pkgs.bashInteractive;

        # Tailnet throughput checks (client is in core-tools). Deliberately not
        # `openFirewall`: reachable on tailscale0 only, never on the public NIC.
        services.iperf3.enable = true;
        networking.firewall.interfaces.tailscale0 = {
          allowedTCPPorts = [ config.services.iperf3.port ];
          allowedUDPPorts = [ config.services.iperf3.port ];
        };
      };
  };
}
