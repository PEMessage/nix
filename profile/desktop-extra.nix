{ config, ... }:
{
  flake.modules.nixos.desktop-extra.imports = [
    config.flake.modules.nixos.apollo
    config.flake.modules.nixos.gaming
    config.flake.modules.nixos.appimage
    config.flake.modules.nixos.ime
  ];
}
