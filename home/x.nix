# x: desktop (X11 / Wayland) home configuration.
# Enabled on real desktop hosts, not on WSL.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./modules/niri-config.nix
    ./modules/noctalia.nix
  ];
}
