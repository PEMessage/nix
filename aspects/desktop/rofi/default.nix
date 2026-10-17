{ config, ... }:
let
  fp = config;
in
{
  flake.aspects.rofi = {
    nixos =
      { ... }:
      {
        home-manager.sharedModules = [ fp.flake.modules.homeManager.rofi ];
      };

    homeManager =
      { config, ... }:
      {
        # Replaces fuzzel. rofi is dedicated to *window switching*: niri
        # implements ext-foreign-toplevel-list-v1, which rofi 2.0's Wayland
        # window mode uses to list and activate toplevels. DMS keeps the
        # application launcher on Mod+Space.
        programs.niri.settings.binds."Mod+D" = {
          hotkey-overlay.title = "Switch windows (rofi)";
          action.spawn = [ "rofi" "-show" "window" ];
        };

        programs.rofi = {
          enable = true;
          location = "center";
          font = "Cascadia Code 12";
          # only the window switcher is enabled; drun/run/ssh stay off.
          modes = [ "window" ];
          # the theme is not written by home-manager: matugen renders it from
          # the DMS palette (see the matugen config below) so colors follow the
          # wallpaper. `dms` resolves to ~/.local/share/rofi/themes/dms.rasi.
          theme = "dms";

          extraConfig = {
            show-icons = true;
            # LinkIcons is the DMS-managed icon theme (icons aspect).
            icon-theme = "LinkIcons";
            # rows show the window title only; the icon carries the app.
            window-format = "{t}";
            # shrink to the number of windows instead of a fixed 10 rows.
            fixed-num-lines = false;
            scroll-method = 0;
          };
        };

        # DMS (with runUserMatugenTemplates, set in the dms aspect) merges the
        # [templates] section below into the matugen config it builds, so the
        # rofi theme is re-rendered whenever the wallpaper/theme changes.
        #
        # The bare `[templates]` line is required: DMS extracts that section
        # textually and looks for this literal marker, so a lone
        # `[templates.rofi]` would be dropped.
        xdg.configFile."matugen/config.toml".text = ''
          [config]

          [templates]

          [templates.rofi]
          input_path = '${./rofi.rasi}'
          output_path = '${config.xdg.dataHome}/rofi/themes/dms.rasi'
        '';
      };
  };
}
