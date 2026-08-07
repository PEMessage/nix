{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    vim
    which
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
