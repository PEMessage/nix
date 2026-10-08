{ config, ... }:
{
  flake.aspects."user.nixos".nixos = {
    users.users.nixos.extraGroups = [ "dialout" ];

    home-manager.users.nixos.imports = [
      config.flake.modules.homeManager.home-manager
      config.flake.modules.homeManager.shell
    ];
  };
}
