# dms: DankMaterialShell — a complete Wayland desktop shell
# (panel, launcher, notification center, clipboard, lock screen).
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  user = config.home.userName;
in
{
  imports = [
    inputs.dms.nixosModules.default
  ];

  programs.dank-material-shell = {
    enable = true;
    # Autostart and keybinds are handled by the DMS niri home-manager module
    # (programs.dank-material-shell.niri) below; the systemd unit stays off so
    # only one instance is spawned.
  };

  # The graphical session can't read gsettings (no schemas in the session's
  # XDG_DATA_DIRS), so GTK/Qt fall back to the hardcoded default icon theme
  # "Adwaita". Installing the theme makes that fallback resolve; without it,
  # themed icons (e.g. the fcitx5 tray icon) render as black/pink checkered
  # placeholders.
  environment.systemPackages = [
    pkgs.adwaita-icon-theme
  ];

  home-manager.users.${user} =
    { ... }:
    {
      imports = [
        inputs.dms.homeModules.dank-material-shell
        inputs.dms.homeModules.niri
      ];

      programs.dank-material-shell = {
        enable = true;
        niri = {
          # DMS preset keybinds (launcher, notifications, settings, lock,
          # powermenu, clipboard, volume/brightness keys, ...).
          enableKeybinds = true;
          # Auto-start DMS with niri (dms run in spawn-at-startup).
          enableSpawn = true;
          includes = {
            # The includes hack would overwrite our managed config.kdl entry
            # point, so it stays off; the same dms/*.kdl files are included
            # manually through niriConfig.lines below instead.
            enable = false;
          };
        };
      };

      # Include the DMS-generated integration files (created with `dms setup`,
      # e.g. `dms setup binds`) into the niri config entry point. `optional`
      # means niri skips files that haven't been generated yet, so no error on
      # a fresh install.
      niriConfig.lines = [
        "include optional=true \"dms/alttab.kdl\";"
        "include optional=true \"dms/binds.kdl\";"
        "include optional=true \"dms/colors.kdl\";"
        "include optional=true \"dms/cursor.kdl\";"
        "include optional=true \"dms/layout.kdl\";"
        "include optional=true \"dms/outputs.kdl\";"
        "include optional=true \"dms/windowrules.kdl\";"
        "include optional=true \"dms/wpblur.kdl\";"
      ];

      programs.niri.settings = {
        # Let the DMS wallpaper render behind windows instead of as a layer
        # that fights with the backdrop. See
        # https://danklinux.com/docs/dankmaterialshell/compositors#layer-rules
        layer-rules = [
          {
            matches = [
              {
                namespace = "^quickshell$";
              }
            ];
            place-within-backdrop = true;
          }
        ];
      };
    };
}
