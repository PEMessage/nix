{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  home.stateVersion = "26.05";
  home.packages = with pkgs; [
    nixfmt
    tree-sitter
    gh
    chezmoi
  ];

  home.file.".profile".text = ''
    # if running bash
    if [ -n "$BASH_VERSION" ]; then
      # include .bashrc if it exists
      if [ -f "$HOME/.bashrc" ]; then
      . "$HOME/.bashrc"
      fi
    fi
  '';

  home.activation.runChezmoi = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "$HOME/.local/share/chezmoi" ] ; then
        echo "Initializing chezmoi dotfiles..." ;
    ${pkgs.chezmoi}/bin/chezmoi init --branch linux-v2 --apply pemessage --depth 1 ;
    fi
  '';

}
