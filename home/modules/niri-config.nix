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
    };
  };

}
