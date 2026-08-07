{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    neovim
    fzf
    ripgrep
    tealdeer
  ];

  # will auto enable nix-community/nix-zsh-completions
  programs.zsh.enable = true;
  environment.shells = [ pkgs.zsh ];
  users.defaultUserShell = pkgs.zsh;

}
