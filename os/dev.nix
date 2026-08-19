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
  ];

  # home-manager: inject this feature's home config into every home user.
  home-manager.sharedModules = [
    (
      { lib, pkgs, ... }:
      {
        home.packages = with pkgs; [
          gh
          nixfmt
          tree-sitter
          chezmoi
        ];

        home.file.".peprofile".text = ''
          "$(command -v bun)" > /dev/null && export PATH="$HOME/.bun/bin:$PATH"
        '';

        home.activation.runChezmoi = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          if [ ! -d "$HOME/.local/share/chezmoi" ] ; then
              echo "Initializing chezmoi dotfiles..." ;
          ${pkgs.chezmoi}/bin/chezmoi init --branch linux-v2 --apply pemessage --depth 1 ;
          fi
        '';
      }
    )
  ];
}
