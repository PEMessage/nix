{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    neovim
    zsh
    chezmoi
  ];
}
