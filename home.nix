{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  load_bashrc = ''
    # if running bash
    if [ -n "$BASH_VERSION" ]; then
      # include .bashrc if it exists
      if [ -f "$HOME/.bashrc" ]; then
      . "$HOME/.bashrc"
      fi
    fi
  '';
  load_bun = ''
    "$(command -v bun)" > /dev/null && export PATH="$HOME/.bun/bin:$PATH"
  '';

in
{
  home.stateVersion = "26.05";
  home.packages = with pkgs; [
    nixfmt
    tree-sitter
    gh
    chezmoi
  ];

  home.file.".profile".text = load_bashrc;

  home.file.".peprofile".text = load_bun;

  home.activation.runChezmoi = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "$HOME/.local/share/chezmoi" ] ; then
        echo "Initializing chezmoi dotfiles..." ;
    ${pkgs.chezmoi}/bin/chezmoi init --branch linux-v2 --apply pemessage --depth 1 ;
    fi
  '';

}
