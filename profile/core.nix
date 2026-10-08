{ config, ... }:
{
  flake.modules.nixos.core.imports = [
    config.flake.modules.nixos.home-manager
  ];
}
