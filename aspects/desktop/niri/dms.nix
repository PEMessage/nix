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

        programs.dank-material-shell.enable = true;

        environment.systemPackages = [
          pkgs.inotify-tools # dms-plugin-registry wallpaperBing daemon dependency
        ];

        home-manager.sharedModules = [ config.flake.modules.homeManager.dms ];
      };

    homeManager =
      { ... }:
      {
        imports = [
          inputs.dms.homeModules.dank-material-shell
          inputs.dms.homeModules.niri
          inputs.dms-plugin-registry.homeModules.default
          inputs.dsearch.homeModules.default
        ];

        programs.dank-material-shell = {
          enable = true;
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
          };

          managePluginSettings = true;
          settings = {
            configVersion = 16;

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
            barConfigs = [
              {
                id = "default";
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
                centerWidgets = [
                  "music"
                  "clock"
                  "weather"
                ];
                rightWidgets = [
                  "systemTray"
                  "clipboard"
                  "cpuUsage"
                  "memUsage"
                  "notificationButton"
                  "battery"
                  "controlCenterButton"
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
              }
            ];
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
}
