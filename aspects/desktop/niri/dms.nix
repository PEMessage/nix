{ config, inputs, ... }:
{
  flake.aspects.dms = {
    nixos =
      { pkgs, ... }:
      {
        imports = [
          inputs.dms.nixosModules.default
          config.flake.modules.nixos.icons
        ];

        # 2.x is packaged in unstable; use it instead of compiling locally.

        programs.dank-material-shell = {
          enable = true;
          package = pkgs.unstable.dux-shell;
          quickshell.package = pkgs.unstable.quickshell;
        };

        environment.systemPackages = [
          pkgs.inotify-tools # dms-plugin-registry wallpaperBing daemon dependency
        ];

        home-manager.sharedModules = [ config.flake.modules.homeManager.dms ];
      };

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        imports = [
          inputs.dms.homeModules.dank-material-shell
          inputs.dms.homeModules.niri
          inputs.dms-plugin-registry.homeModules.default
          inputs.dsearch.homeModules.default
        ];

        # Named bar configs keyed by id. Host modules can overlay a bar by
        # id (e.g. dms.barConfigs.default.rightWidgets = lib.mkBefore [...]).
        options.dms.barConfigs = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              freeformType = (pkgs.formats.json { }).type;
              options.rightWidgets = lib.mkOption {
                # Widget entries are normally strings, but a widget can also be
                # an object carrying per-widget options (clockCompactMode and
                # the like), mirroring what DMS itself stores.
                type = lib.types.listOf (
                  lib.types.either lib.types.str (lib.types.attrsOf lib.types.anything)
                );
                default = [ ];
              };
            }
          );
          default = { };
        };

        config = {
          dms.barConfigs.default = {
            name = "Main Bar";
            enabled = true;
            position = 0;
            screenPreferences = [ "all" ];
            showOnLastDisplay = true;
            leftWidgets = [
              "launcherButton"
              "workspaceSwitcher"
              "focusedWindow"
              "unifiedTaskbar"
            ];
            # Just the clock in the middle; music/weather live in the control
            # center (or not at all), keeping the bar quiet. Compact mode drops
            # the date so the center is only the time.
            centerWidgets = [
              {
                id = "clock";
                clockCompactMode = true;
              }
            ];
            # Only the widgets that need at-a-glance access. Clipboard is
            # Mod+V, the process list is Mod+M, and CPU/RAM are a control-center
            # tile now. The tray collapses to one icon plus overflow, and the
            # control-center button shows just its own icon instead of a row of
            # network/bluetooth/audio status icons.
            rightWidgets = [
              {
                id = "systemTray";
                trayAutoOverflow = true;
                trayMaxVisibleItems = 3;
              }
              "notificationButton"
              {
                id = "controlCenterButton";
                showNetworkIcon = false;
                showBluetoothIcon = false;
                showAudioIcon = false;
              }
            ];
            spacing = 12;
            innerPadding = 4;
            barLengthPadding = 0;
            bottomGap = 0;
            attachToScreenEdge = false;
            transparency = 0.59;
            widgetTransparency = 0.2;
            squareCorners = false;
            noBackground = false;
            maximizeWidgetIcons = false;
            maximizeWidgetText = false;
            removeWidgetPadding = false;
            widgetPadding = 8;
            gothCornersEnabled = false;
            gothCornerRadiusOverride = false;
            gothCornerRadiusValue = 12;
            borderEnabled = false;
            borderColor = "surfaceText";
            borderOpacity = 1;
            borderThickness = 1;
            widgetOutlineEnabled = false;
            widgetOutlineColor = "primary";
            widgetOutlineOpacity = 1;
            widgetOutlineThickness = 1;
            fontScale = 1;
            iconScale = 1;
            autoHide = false;
            autoHideStrict = false;
            autoHideDelay = 250;
            showOnWindowsOpen = false;
            openOnOverview = false;
            visible = true;
            popupGapsAuto = true;
            popupGapsManual = 4;
            maximizeDetection = true;
            useOverlayLayer = false;
            scrollEnabled = true;
            scrollXBehavior = "column";
            scrollYBehavior = "workspace";
            shadowIntensity = 0;
            shadowOpacity = 60;
            shadowColorMode = "default";
            shadowCustomColor = "#000000";
            clickThrough = false;
            hoverPopouts = false;
            hoverPopoutDelay = 150;
          };

          programs.dank-material-shell = {
            enable = true;
            package = pkgs.unstable.dux-shell;
            quickshell.package = pkgs.unstable.quickshell;
            niri = {
              # DMS preset keybinds (launcher, notifications, settings, lock,
              # powermenu, clipboard, volume/brightness keys, ...).
              enableKeybinds = true;
              # auto-start DMS with niri (dms run in spawn-at-startup).
              enableSpawn = true;
              # the includes hack would overwrite our managed config.kdl entry
              # point; the same dms/*.kdl files are included manually below.
              includes.enable = false;
            };

            plugins = {
              wallpaperBing.enable = true;
              wallpaperBingWidget.enable = true;
              unifiedTaskbar.enable = true;
              cpuStats.src = ./dms-plugins/cpuStats;
              memStats.src = ./dms-plugins/memStats;
            };

            managePluginSettings = true;
            settings = {
              configVersion = 42;

              # Let DMS run the user matugen templates from
              # ~/.config/matugen/config.toml; the rofi aspect renders its
              # window-switcher theme there so it follows the dynamic palette.
              runUserMatugenTemplates = true;

              theme = "dark";
              dynamicTheming = true;
              currentThemeName = "dynamic";
              currentThemeCategory = "dynamic";

              # DMS-managed icon theme: the single meta-theme LinkIcons
              # (LinkIcons -> Papirus-Dark -> breeze-dark -> Adwaita -> hicolor).
              # perMode is off, so only iconThemeDark is used.
              iconThemeDark = "LinkIcons";

              # blur
              blurEnabled = true;
              blurWallpaperOnOverview = true;
              popupTransparency = 0.65;
              foregroundLayerTransparency = 0.8;
              blurLayerOutlineOpacity = 0.2;
              # Control-center layout. This mirrors the SettingsSpec defaults
              # (re-sync when DMS adds a new default tile) plus the local
              # systemStats plugin tile: CPU/RAM moved here from the bar.
              controlCenterWidgets = [
                { id = "user"; enabled = true; w = 5; h = 1; }
                { id = "settings"; enabled = true; w = 1; h = 1; small = true; }
                { id = "lock"; enabled = true; w = 1; h = 1; small = true; }
                { id = "power"; enabled = true; w = 1; h = 1; small = true; }
                { id = "brightnessSlider"; enabled = true; w = 4; h = 1; small = true; }
                { id = "volumeSlider"; enabled = true; w = 4; h = 1; small = true; }
                { id = "wifi"; enabled = true; w = 4; h = 1; }
                { id = "bluetooth"; enabled = true; w = 4; h = 1; }
                { id = "audioOutput"; enabled = true; w = 4; h = 1; }
                { id = "audioInput"; enabled = true; w = 4; h = 1; }
                { id = "darkMode"; enabled = true; w = 2; h = 1; }
                { id = "nightMode"; enabled = true; w = 2; h = 1; }
                { id = "doNotDisturb"; enabled = true; w = 2; h = 1; }
                { id = "idleInhibitor"; enabled = true; w = 2; h = 1; }
                { id = "battery"; enabled = true; w = 4; h = 1; }
                { id = "diskUsage"; enabled = true; w = 4; h = 1; }
                { id = "plugin_cpuStats"; enabled = true; w = 4; h = 1; }
                { id = "plugin_memStats"; enabled = true; w = 4; h = 1; }
                { id = "runningApps"; enabled = true; w = 7; h = 1; small = true; }
                { id = "edit"; enabled = true; w = 1; h = 1; small = true; }
              ];

              barConfigs = lib.mapAttrsToList (id: bar: bar // { inherit id; }) config.dms.barConfigs;
            };
          };

          # dsearch: indexed filesystem search daemon (config generated on first run).
          programs.dsearch.enable = true;

          # include the DMS-generated integration files (dms setup) into the niri
          # config entry point; `optional` skips files not generated yet.
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
            # let the DMS wallpaper render behind windows instead of fighting the backdrop
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

      };
  };
}
