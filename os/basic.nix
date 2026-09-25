# Basic layer shared by workstations *and* headless servers: small tools that
# are useful (or at least harmless) without a GUI, plus the Tailscale client.
# Wired up in flake.nix as a layer between `os/core.nix` and `os/dev.nix`, so
# the `vps` host gets this without the heavy dev toolchain
# (rustc/cargo/gdb/bun) that os/dev.nix adds.
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # iperf3 client (the daemon is enabled in os/server.nix)
    iperf3

    # dotfiles
    chezmoi

    # python tooling
    uv
  ];

  # Tailscale mesh VPN, available on every host that imports basic/dev (wsl,
  # desktop, servers). To join a tailnet run `tailscale up` once. On WSL2 this
  # needs /dev/net/tun (usually present); if not, use
  # `tailscale up --tun=userspace-networking`.
  services.tailscale.enable = true;

  # home-manager: chezmoi bootstrap helper, injected into every home user.
  home-manager.sharedModules = [
    {
      script.pe-chezmoi-init = ./scripts/pe-chezmoi-init;
    }
  ];
}
