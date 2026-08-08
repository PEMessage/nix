{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.stateVersion = "26.05";

  home.file.".profile".text = ''
    # if running bash
    if [ -n "$BASH_VERSION" ]; then
      # include .bashrc if it exists
      if [ -f "$HOME/.bashrc" ]; then
      . "$HOME/.bashrc"
      fi
    fi
  '';
}
