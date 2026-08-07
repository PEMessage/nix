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
  ];

  home.activation.runChezmoi = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "$HOME/.local/share/chezmoi" ] ; then
        echo "Initializing chezmoi dotfiles..." ;
    ${pkgs.chezmoi}/bin/chezmoi init --branch linux-v2 --apply pemessage --depth 1 ;
    fi
  '';

}
