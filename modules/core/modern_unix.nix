{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    neovim
    chezmoi
  ];

  # will auto enable nix-community/nix-zsh-completions
  programs.zsh.enable = true;


  environment.shells = [ pkgs.zsh ];

}
