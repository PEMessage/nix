{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # c/c++
    gdb

    # rust
    rustc
    cargo

    # bun
    bun

    # uv
    uv

    # chezmoi + one-command init helper
    chezmoi
    iperf3
  ];

  # Tailscale mesh VPN, available on every host that imports dev (wsl, desktop,
  # servers). To join a tailnet run `tailscale up` once. On WSL2 this needs
  # /dev/net/tun (usually present); if not, use
  # `tailscale up --tun=userspace-networking`.
  services.tailscale.enable = true;

  # home-manager: inject this feature's home config into every home user.
  home-manager.sharedModules = [
    (
      { lib, pkgs, ... }:
      {
        home.packages = with pkgs; [
          gh
          nixfmt
          tree-sitter
        ];

        # one-command convenience scripts on PATH
        script = {
          pe-chezmoi-init = ./scripts/pe-chezmoi-init;
        };

        home.file.".peprofile".text = ''
          "$(command -v bun)" > /dev/null && export PATH="$HOME/.bun/bin:$PATH"
        '';
      }
    )
  ];
}
