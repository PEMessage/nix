# x: desktop (X11 / Wayland) home configuration.
# Enabled on real desktop hosts, not on WSL.
{
  config,
  lib,
  pkgs,
  ...
}: {
  # niri / dms configuration now lives in os/modules/niri.nix
  # and os/modules/dms.nix (which niri.nix imports).
}
