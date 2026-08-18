# x: desktop (X11 / Wayland) home configuration.
# Enabled on real desktop hosts, not on WSL.
{
  config,
  lib,
  pkgs,
  ...
}: {
  # niri / noctalia configuration now lives in os/modules/niri.nix
  # and os/modules/noctalia.nix (which niri.nix imports).
}
