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

}
