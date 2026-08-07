{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    vim
    which
    python3

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

}
