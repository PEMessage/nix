
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

  users.users.${config.wsl.defaultUser} = {
    extraGroups = [ "dialout" ]; # Allow the default user to use sudo
  };
}
