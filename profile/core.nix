{ config, ... }:
{
  flake.modules.nixos.core.imports = [
    config.flake.modules.nixos.nix
    config.flake.modules.nixos.home-manager
    config.flake.modules.nixos.core-tools
    config.flake.modules.nixos.shell
  ];
}
