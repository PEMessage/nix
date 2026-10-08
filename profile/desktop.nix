{ config, ... }:
{
  flake.modules.nixos.desktop.imports = [
    config.flake.modules.nixos.core
    config.flake.modules.nixos.dev-tools
    config.flake.modules.nixos.fonts
    config.flake.modules.nixos.graphics
    config.flake.modules.nixos.core-app
    config.flake.modules.nixos.gaming
    config.flake.modules.nixos.flatpak
    config.flake.modules.nixos.appimage
  ];
}
