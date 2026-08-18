# niri: scrollable-tiling Wayland compositor (replaces GNOME on desktop hosts).
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
    inputs.niri.nixosModules.niri
    ./dms.nix
  ];

  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  # Lightweight login manager with autologin straight into niri.
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.niri}/bin/niri-session";
        user = user;
      };
    };
  };

  # No display manager needed, greetd takes over the login screen.
  services.displayManager.enable = false;

  environment.systemPackages = with pkgs; [
    fuzzel
    swaylock
  ];

  home-manager.users.${user} =
    { config, lib, ... }:
    {
      # Lines that other modules (e.g. dms.nix) can contribute to the niri
      # config entry point; they land between nix.kdl and local.kdl so that
      # unmanaged local overrides still win.
      options.niriConfig.lines = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra include lines for the niri config entry point (config.kdl).";
      };

      config = {
        # Entry point: the generated settings (nix.kdl), module-contributed
        # lines, then optional unmanaged local overrides (local.kdl).
        xdg.configFile."niri/config.kdl".text = lib.concatLines (
          [ "include \"nix.kdl\";" ] ++ config.niriConfig.lines ++ [ "include optional=true \"local.kdl\";" ]
        );

        # Rename the generated settings file so config.kdl can include it as nix.kdl.
        xdg.configFile.niri-config.target = lib.mkForce "niri/nix.kdl";

        programs.niri.settings = {
          window-rules = [
            {
              geometry-corner-radius = {
                top-left = 12.0;
                top-right = 12.0;
                bottom-right = 12.0;
                bottom-left = 12.0;
              };
              clip-to-geometry = true;
            }
          ];

          binds = {
            "Mod+Shift+Slash".action.show-hotkey-overlay = [ ];
            "Mod+T" = {
              hotkey-overlay = {
                title = "Open a Terminal: ghostty";
              };
              action.spawn = [ "ghostty" ];
            };
            "Mod+O" = {
              repeat = false;
              action.toggle-overview = [ ];
            };
            "Mod+Q" = {
              repeat = false;
              action.close-window = [ ];
            };

            # Arrows
            "Mod+Left".action.focus-column-left = [ ];
            "Mod+Down".action.focus-window-down = [ ];
            "Mod+Up".action.focus-window-up = [ ];
            "Mod+Right".action.focus-column-right = [ ];

            "Mod+Ctrl+Left".action.move-column-left = [ ];
            "Mod+Ctrl+Down".action.move-window-down-or-to-workspace-down = [ ];
            "Mod+Ctrl+Up".action.move-window-up-or-to-workspace-up = [ ];
            "Mod+Ctrl+Right".action.move-column-right = [ ];

            # H J K L
            "Mod+H".action.focus-column-left = [ ];
            "Mod+J".action.focus-window-or-workspace-down = [ ];
            "Mod+K".action.focus-window-or-workspace-up = [ ];
            "Mod+L".action.focus-column-right = [ ];

            "Mod+Ctrl+H".action.move-column-left = [ ];
            "Mod+Ctrl+J".action.move-window-down-or-to-workspace-down = [ ];
            "Mod+Ctrl+K".action.move-window-up-or-to-workspace-up = [ ];
            "Mod+Ctrl+L".action.move-column-right = [ ];

            # Move
            "Mod+BracketLeft".action.consume-or-expel-window-left = [ ];
            "Mod+BracketRight".action.consume-or-expel-window-right = [ ];

            # Expel the bottom window from the focused column to the right.
            # (Mod+Comma, the consume counterpart, is taken by the DMS keybinds.)
            "Mod+Period".action.expel-window-from-column = [ ];

            "Mod+R".action.switch-preset-column-width = [ ];
            # Cycling through the presets in reverse order is also possible.
            "Mod+Shift+R".action.switch-preset-column-width-back = [ ];

            "Mod+Ctrl+Shift+R".action.switch-preset-window-height = [ ];
            "Mod+Ctrl+R".action.reset-window-height = [ ];

            # Finer width adjustments.
            "Mod+Minus".action.set-column-width = [ "-10%" ];
            "Mod+Equal".action.set-column-width = [ "+10%" ];

            # Finer height adjustments when in column with other windows.
            "Mod+Shift+Minus".action.set-window-height = [ "-10%" ];
            "Mod+Shift+Equal".action.set-window-height = [ "+10%" ];

            "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = [ ];

            "Mod+F".action.maximize-column = [ ];
            "Mod+Shift+F".action.fullscreen-window = [ ];

            # Expand the focused column to space not taken up by other fully
            # visible columns. Makes the column "fill the rest of the space".
            "Mod+Ctrl+F".action.expand-column-to-available-width = [ ];

            # Mouse
            "Mod+WheelScrollDown" = {
              cooldown-ms = 150;
              action.focus-workspace-down = [ ];
            };
            "Mod+WheelScrollUp" = {
              cooldown-ms = 150;
              action.focus-workspace-up = [ ];
            };
            "Mod+Ctrl+WheelScrollDown" = {
              cooldown-ms = 150;
              action.move-column-to-workspace-down = [ ];
            };
            "Mod+Ctrl+WheelScrollUp" = {
              cooldown-ms = 150;
              action.move-column-to-workspace-up = [ ];
            };

            "Print".action.screenshot = [ ];
            "Ctrl+Print".action.screenshot-screen = [ ];
            "Alt+Print".action.screenshot-window = [ ];
            "Mod+Shift+S".action.screenshot = [ ];
            "Ctrl+Alt+Delete".action.quit = [ ];

            # Extra
            # Volume and brightness keys are handled by the DMS preset keybinds
            # (via `dms ipc`, with OSD feedback), so they are not defined here.

            # Media keys mapping using playerctl.
            # This will work with any MPRIS-enabled media player.
            "XF86AudioPlay" = {
              allow-when-locked = true;
              action.spawn-sh = [ "playerctl play-pause" ];
            };
            "XF86AudioStop" = {
              allow-when-locked = true;
              action.spawn-sh = [ "playerctl stop" ];
            };
            "XF86AudioPrev" = {
              allow-when-locked = true;
              action.spawn-sh = [ "playerctl previous" ];
            };
            "XF86AudioNext" = {
              allow-when-locked = true;
              action.spawn-sh = [ "playerctl next" ];
            };
          };
        };
      };
    };
}
