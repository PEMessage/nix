{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    vim
    which
    python3
    tmux

    # build
    gcc
    gnumake
    binutils
    autoconf
    automake
  ];
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  programs.bash.enable = true;

  #Error during "tree-sitter build": Could not start dynamically linked executable: tree-sitter
  #NixOS cannot run dynamically linked executables intended for generic
  #linux environments out of the box. For more information, see:
  #https://nix.dev/permalink/stub-ld
  programs.nix-ld.enable = true;

}
