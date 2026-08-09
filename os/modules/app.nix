{ config, lib, pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    ghostty
    google-chrome
    deskflow
    xclip
  ];
}
