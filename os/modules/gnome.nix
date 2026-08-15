{ config, lib, pkgs, inputs, ... }:
{
  services.displayManager.gdm.enable = true;
  services.displayManager.autoLogin = {
    enable = true;
    user = config.home.userName;
  };
  services.desktopManager.gnome.enable = true;

  # Remote Desktop
  # ==========================

  # See: https://nixos.wiki/wiki/Remote_Desktop#GNOME
  services.gnome.gnome-remote-desktop.enable = true;
  # Ensure the service starts automatically at boot so the settings panel appears
  systemd.services.gnome-remote-desktop = {
    wantedBy = [ "graphical.target" ];
  };
  # Open the default RDP port (3389)
  networking.firewall.allowedTCPPorts = [ 3389 ];

  # Trim
  # ==========================

  # Trim GNOME defaults: no games, and drop the core apps we don't use.
  # Kept: nautilus, gnome-console, gnome-text-editor, gnome-calculator,
  # gnome-control-center, seahorse, snapshot, loupe, gnome-system-monitor.
  services.gnome.games.enable = false;
  environment.gnome.excludePackages = with pkgs; [
    baobab
    decibels
    epiphany
    gnome-calendar
    gnome-characters
    gnome-clocks
    gnome-connections
    gnome-contacts
    gnome-font-viewer
    gnome-logs
    gnome-maps
    gnome-music
    gnome-tecla
    gnome-tour
    gnome-weather
    papers
    showtime
    simple-scan
    yelp
  ];

  imports = [ inputs.gnome-rounded-blur.nixosModules.default ];


  # AppIndicator tray icons (fcitx5 status icon), Kimpanel (fcitx5
  # candidate popup over GNOME Shell), blur-my-shell (overview blur),
  # dash-to-dock (dock), Papirus icon theme.
  environment.systemPackages = with pkgs; [
    gnomeExtensions.appindicator
    gnomeExtensions.kimpanel
    gnomeExtensions.blur-my-shell
    # gnomeExtensions.dash-to-dock
    gnomeExtensions.dynamic-wallpaper-fetcher
    # gnomeExtensions.rounded-window-corners
    gnomeExtensions.paperwm
    papirus-icon-theme
  ];

  # Enable the extensions declaratively (docs: install via systemPackages,
  # enable via dconf, since NixOS has no gnome.extensions option anymore).
  home-manager.users.${config.home.userName}.dconf.settings = {
    # Never auto-lock the screen
    "org/gnome/desktop/screensaver" = {
      lock-enabled = false;
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = ":minimize,maximize,close";
    };

    "org/gnome/desktop/wm/keybindings" = {
      toggle-quick-settings = []; # remove Super+S
      close = [ "<Super>q" ];
    };

    # Thanks to: https://github.com/gierens/dotfiles/blob/e0beaad0658427b63bf618be62589fc826aa70be/home/dconf.nix#L34-L40
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/browser/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/files/"
      ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal" = {
      binding = "<Super>t";
      command = "ghostty";
      name = "terminal";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/browser" = {
      binding = "<Super>b";
      command = "google-chrome";
      name = "browser";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/files" = {
      binding = "<Super>e";
      command = "nautilus";
      name = "files";
    };


    # ==========================
    # Extensions
    # ==========================

    "org/gnome/shell" = {
      enabled-extensions = with pkgs.gnomeExtensions; [
        appindicator.extensionUuid
        kimpanel.extensionUuid
        blur-my-shell.extensionUuid
        # dash-to-dock.extensionUuid
        dynamic-wallpaper-fetcher.extensionUuid
        # rounded-window-corners.extensionUuid
        paperwm.extensionUuid
      ];
    };

    # Theme: dark mode + Papirus icons
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      icon-theme = "Papirus-Dark";
    };



    # blur-my-shell
    # ==========================

    "org/gnome/shell/extensions/blur-my-shell/overview" = {
      style-components = 3;
    };

    # "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
    #   static-blur = false;
    #   corner-radius = 28;
    # };

    # paperwm
    # ==========================
    "org/gnome/shell/extensions/paperwm" = {
      # rounded-conner
      selection-border-radius-bottom  = 20;
      selection-border-radius-top     = 20;

      # margin
      selection-border-size           = 10;
      window-gap                      = 20;
      vertical-margin                 = 14;
      bottom-margin                   = 14;
      vertical-margin-bottom          = 14;

      # topbar icons
      show-workspace-indicator        = false;
      show-focus-mode-icon            = true;
      show-open-position-icon         = false;
    };

    "org/gnome/shell/extensions/paperwm/keybindings" = {
      take-window  = []; # Remove Super+T
      live-alt-tab = ["<Alt>Tab"]; # Remove Super+Tab
    };

  };
}
