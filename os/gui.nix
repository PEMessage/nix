{ config, pkgs, ... }:
{
  fonts.packages = with pkgs; [
    cascadia-code
  ];
}
