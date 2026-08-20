
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  time.timeZone = "Asia/Shanghai";
  networking.hostName = "wsl"; # Define your hostname.
}
