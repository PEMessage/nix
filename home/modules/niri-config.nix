{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Entry point: the generated settings plus optional unmanaged local overrides.
  xdg.configFile."niri/config.kdl".text = ''
    include "nix.kdl";
    include optional=true "local.kdl";
  '';

  # Rename the generated settings file so config.kdl can include it as nix.kdl.
  xdg.configFile.niri-config.target = lib.mkForce "niri/nix.kdl";

  programs.niri.settings = {
    spawn-at-startup = [
      {
        argv = [
          "noctalia"
        ];
      }
    ];

    binds = {
      "Mod+Shift+Slash".action.show-hotkey-overlay = [];
      "Mod+T" = {
        hotkey-overlay = {
          title = "Open a Terminal: ghostty";
        };
        action.spawn = [ "ghostty" ];
      };
      "Mod+D" = {
        hotkey-overlay = {
          title = "Run an Application: fuzzel";
        };
        action.spawn = [ "fuzzel" ];
      };
      "Mod+O" = { repeat = false; action.toggle-overview = []; };
      "Mod+Q" = { repeat = false; action.close-window = []; };

      # Arrows
      "Mod+Left".action.focus-column-left = [];
      "Mod+Down".action.focus-window-down = [];
      "Mod+Up".action.focus-window-up = [];
      "Mod+Right".action.focus-column-right = [];

      "Mod+Ctrl+Left".action.move-column-left = [];
      "Mod+Ctrl+Down".action.move-window-down-or-to-workspace-down = [];
      "Mod+Ctrl+Up".action.move-window-up-or-to-workspace-up = [];
      "Mod+Ctrl+Right".action.move-column-right = [];

      # H J K L
      "Mod+H".action.focus-column-left = [];
      "Mod+J".action.focus-window-or-workspace-down = [];
      "Mod+K".action.focus-window-or-workspace-up = [];
      "Mod+L".action.focus-column-right = [];

      "Mod+Ctrl+H".action.move-column-left = [];
      "Mod+Ctrl+J".action.move-window-down-or-to-workspace-down = [];
      "Mod+Ctrl+K".action.move-window-up-or-to-workspace-up = [];
      "Mod+Ctrl+L".action.move-column-right = [];

      # Move
      "Mod+BracketLeft".action.consume-or-expel-window-left = [];
      "Mod+BracketRight".action.consume-or-expel-window-right = [];

      # Consume one window from the right to the bottom of the focused column.
      "Mod+Comma".action.consume-window-into-column = [];
      # Expel the bottom window from the focused column to the right.
      "Mod+Period".action.expel-window-from-column = [];

      "Mod+R".action.switch-preset-column-width = [];
      # Cycling through the presets in reverse order is also possible.
      "Mod+Shift+R".action.switch-preset-column-width-back = [];

      "Mod+Ctrl+Shift+R".action.switch-preset-window-height = [];
      "Mod+Ctrl+R".action.reset-window-height = [];

      # Finer width adjustments.
      "Mod+Minus".action.set-column-width = [ "-10%" ];
      "Mod+Equal".action.set-column-width = [ "+10%" ];

      # Finer height adjustments when in column with other windows.
      "Mod+Shift+Minus".action.set-window-height = [ "-10%" ];
      "Mod+Shift+Equal".action.set-window-height = [ "+10%" ];

      # Move the focused window between the floating and the tiling layout.
      "Mod+V".action.toggle-window-floating = [];
      "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = [];

      "Mod+F".action.maximize-column = [];
      "Mod+Shift+F".action.fullscreen-window = [];

      # While maximize-column leaves gaps and borders around the window,
      # maximize-window-to-edges doesn't: the window expands to the edges
      # of the screen. This bind corresponds to normal window maximizing,
      # e.g. by double-clicking on the titlebar.
      "Mod+M".action.maximize-window-to-edges = [];

      # Expand the focused column to space not taken up by other fully
      # visible columns. Makes the column "fill the rest of the space".
      "Mod+Ctrl+F".action.expand-column-to-available-width = [];

      # Mouse
      "Mod+WheelScrollDown" = { cooldown-ms = 150; action.focus-workspace-down = []; };
      "Mod+WheelScrollUp" = { cooldown-ms = 150; action.focus-workspace-up = []; };
      "Mod+Ctrl+WheelScrollDown" = { cooldown-ms = 150; action.move-column-to-workspace-down = []; };
      "Mod+Ctrl+WheelScrollUp" = { cooldown-ms = 150; action.move-column-to-workspace-up = []; };

      "Print".action.screenshot = [];
      "Ctrl+Print".action.screenshot-screen = [];
      "Alt+Print".action.screenshot-window = [];
      "Mod+Shift+S".action.screenshot = [];
      "Ctrl+Alt+Delete".action.quit = [];
    };
  };

}
