{ config, lib, pkgs, inputs, ... }:
{
  services.displayManager.gdm.enable = true;
  services.displayManager.autoLogin = {
    enable = true;
    user = config.home.userName;
  };
  services.desktopManager.gnome.enable = true;

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

  # AppIndicator tray icons (fcitx5 status icon), Kimpanel (fcitx5
  # candidate popup over GNOME Shell), blur-my-shell (overview blur),
  # dash-to-dock (dock), Papirus icon theme.
  environment.systemPackages = with pkgs; [
    gnomeExtensions.appindicator
    gnomeExtensions.kimpanel
    gnomeExtensions.blur-my-shell
    gnomeExtensions.dash-to-dock
    gnomeExtensions.dynamic-wallpaper-fetcher
    gnomeExtensions.rounded-window-corners
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

    "org/gnome/shell" = {
      enabled-extensions = with pkgs.gnomeExtensions; [
        appindicator.extensionUuid
        kimpanel.extensionUuid
        blur-my-shell.extensionUuid
        dash-to-dock.extensionUuid
        dynamic-wallpaper-fetcher.extensionUuid
        rounded-window-corners.extensionUuid
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


  };
}
