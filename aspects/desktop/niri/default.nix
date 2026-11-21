{ config, inputs, ... }:
let
  fp = config;
in
{
  flake.aspects.niri = {
    nixos =
      { config, pkgs, ... }:
      let
        # exactly one home-manager user per host; use it as the greetd login user
        userName = builtins.head (builtins.attrNames config.home-manager.users);
        # Use the unstable package (prebuilt) instead of compiling niri.
        niriPkg = pkgs.unstable.niri;
      in
      {
        imports = [
          inputs.niri.nixosModules.niri
          fp.flake.modules.nixos.dux
          fp.flake.modules.nixos.rofi
        ];

        programs.niri = {
          enable = true;
          package = niriPkg;
        };

        # xdg portals (required by flatpak / sandboxed apps)
        xdg.portal = {
          enable = true;
          extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        };

        # Autologin straight into niri.
        #
        # `initial_session` is a real login: greetd opens a PAM session for the
        # user, and that is the session logind reports as the user's display
        # session (Class=user, Type=wayland, seat0). The old form — `niri-session`
        # as `default_session` — ran the compositor as the *greeter*, so this
        # user's only session was Class=greeter, and polkit's
        # `sd_pid_get_session()` (it walks the cgroup) failed for every process
        # of the desktop. polkit then fell back to `sd_uid_get_display()`, whose
        # answer drifted (2 at boot, 3 once something else logged in), so the
        # DMS polkit agent kept registering under a session id that the requests
        # were not in, and no password dialog ever appeared.
        #
        # Note the processes themselves still run in `session.slice/niri.service`
        # (niri-session starts a user unit), not in `session-2.scope`, so the
        # cgroup lookup still fails. What changed is that the fallback now has
        # exactly one answer.
        services.greetd = {
          enable = true;
          settings = {
            initial_session = {
              command = "${niriPkg}/bin/niri-session";
              user = userName;
            };
            # greetd wants a default session; this is also what runs after a
            # logout, and there it is a greeter session again.
            default_session = {
              command = "${niriPkg}/bin/niri-session";
              user = userName;
            };
          };
        };
        services.displayManager.enable = false;

        # remote VNC server
        programs.wayvnc.enable = true;
        networking.firewall.allowedTCPPorts = [ 5900 ];

        services.gvfs.enable = true;

        environment.systemPackages = with pkgs; [
          swaylock
          nautilus
          seahorse
        ];

        home-manager.sharedModules = [ fp.flake.modules.homeManager.niri ];
      };

    homeManager =
      { config, lib, pkgs, inputs, ... }:
      {
        options.niriConfig.lines = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Extra include lines for the niri config entry point (config.kdl).";
        };

        config = {
          # Keep the HM module's validation/package in sync with the session.
          programs.niri.package = pkgs.unstable.niri;

          # entry point: generated settings (nix.kdl), feature-contributed lines,
          # then optional unmanaged local overrides (local.kdl).
          xdg.configFile."niri/config.kdl".text = lib.concatLines (
            [ "include \"nix.kdl\";" ]
            ++ config.niriConfig.lines
            ++ [ "include optional=true \"local.kdl\";" ]
          );
          xdg.configFile.niri-config.target = lib.mkForce "niri/nix.kdl";

          programs.niri.settings = {
            xwayland-satellite = {
              enable = true;
              path = lib.getExe pkgs.unstable.xwayland-satellite;
            };

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
                hotkey-overlay.title = "Open a Terminal: ghostty";
                action.spawn = [ "ghostty" ];
              };
              "Mod+O" = {
                repeat = false;
                action.toggle-overview = [ ];
              };
              "Mod+B" = {
                hotkey-overlay.title = "Open Chrome";
                action.spawn = [ "google-chrome-stable" ];
              };
              "Mod+Q" = {
                repeat = false;
                action.close-window = [ ];
              };

              # arrows
              "Mod+Left".action.focus-column-left = [ ];
              "Mod+Down".action.focus-window-down = [ ];
              "Mod+Up".action.focus-window-up = [ ];
              "Mod+Right".action.focus-column-right = [ ];

              "Mod+Ctrl+Left".action.move-column-left = [ ];
              "Mod+Ctrl+Down".action.move-window-down-or-to-workspace-down = [ ];
              "Mod+Ctrl+Up".action.move-window-up-or-to-workspace-up = [ ];
              "Mod+Ctrl+Right".action.move-column-right = [ ];

              # h j k l
              "Mod+H".action.focus-column-left = [ ];
              "Mod+J".action.focus-window-or-workspace-down = [ ];
              "Mod+K".action.focus-window-or-workspace-up = [ ];
              "Mod+L".action.focus-column-right = [ ];

              "Mod+Ctrl+H".action.move-column-left = [ ];
              "Mod+Ctrl+J".action.move-window-down-or-to-workspace-down = [ ];
              "Mod+Ctrl+K".action.move-window-up-or-to-workspace-up = [ ];
              "Mod+Ctrl+L".action.move-column-right = [ ];

              "Mod+BracketLeft".action.consume-or-expel-window-left = [ ];
              "Mod+BracketRight".action.consume-or-expel-window-right = [ ];

              # expel the bottom window from the focused column to the right
              # (Mod+Comma, the consume counterpart, is taken by the Dux keybinds)
              "Mod+Period".action.expel-window-from-column = [ ];

              "Mod+R".action.switch-preset-column-width = [ ];
              "Mod+Shift+R".action.switch-preset-column-width-back = [ ];

              "Mod+Ctrl+Shift+R".action.switch-preset-window-height = [ ];
              "Mod+Ctrl+R".action.reset-window-height = [ ];

              "Mod+Minus".action.set-column-width = [ "-10%" ];
              "Mod+Equal".action.set-column-width = [ "+10%" ];

              "Mod+Shift+Minus".action.set-window-height = [ "-10%" ];
              "Mod+Shift+Equal".action.set-window-height = [ "+10%" ];

              "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = [ ];

              "Mod+F".action.maximize-column = [ ];
              "Mod+Shift+F".action.fullscreen-window = [ ];

              "Mod+Ctrl+F".action.expand-column-to-available-width = [ ];

              # mouse
              "Mod+WheelScrollDown" = {
                cooldown-ms = 150;
                action.focus-column-right = [ ];
              };
              "Mod+WheelScrollUp" = {
                cooldown-ms = 150;
                action.focus-column-left = [ ];
              };

              "Mod+Shift+WheelScrollDown" = {
                cooldown-ms = 150;
                action.focus-workspace-down = [ ];
              };
              "Mod+Shift+WheelScrollUp" = {
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

              # volume/brightness keys come from the Dux preset keybinds
              # (via `dms ipc`, with OSD feedback), so they are not set here.

              # media keys (MPRIS)
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
  };
}
