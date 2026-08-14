{ config, lib, pkgs, inputs, ... }:
{
  services.displayManager.gdm.enable = true;
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
  # candidate popup over GNOME Shell), shell beautification (blur + dock),
  environment.systemPackages = with pkgs; [
    gnomeExtensions.appindicator
    gnomeExtensions.kimpanel
    gnomeExtensions.blur-my-shell
    papirus-icon-theme
  ];

  # Enable the extensions declaratively (docs: install via systemPackages,
  # enable via dconf, since NixOS has no gnome.extensions option anymore).
  home-manager.users.${config.home.userName}.dconf.settings = {
    "org/gnome/shell" = {
      enabled-extensions = [
        "appindicatorsupport@rgcjonas.gmail.com"
        "kimpanel@kde.org"
        "blur-my-shell@aunetx"
      ];
    };

    # Theme: dark mode + adw-gtk3 + Papirus icons
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      icon-theme = "Papirus-Dark";
    };

  };
}
