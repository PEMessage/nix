{ config, ... }:
{
  flake.modules.nixos.desktop.imports = [
    config.flake.modules.nixos.core
    config.flake.modules.nixos.dev-tools
    config.flake.modules.nixos.fonts
  ];
}
