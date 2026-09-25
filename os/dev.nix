# Heavy development toolchain for workstations (wsl/desktop). Headless servers
# import `os/basic.nix` instead, which carries the lightweight shared tools.
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
  ];

  # appimage support (desktop/WSL only; the headless vps host imports
  # os/basic.nix, not this module, so it doesn't pull in the whole
  # GTK/X stack that appimage-run needs).
  # ===================================
  programs.appimage.enable = true;
  programs.appimage.binfmt = !(config.wsl.enable or false);

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

        home.file.".peprofile".text = ''
          "$(command -v bun)" > /dev/null && export PATH="$HOME/.bun/bin:$PATH"
        '';
      }
    )
  ];
}
