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

  # AppIndicator tray icons (fcitx5 status icon) and Kimpanel (fcitx5
  # candidate popup over GNOME Shell; fcitx's own popup cannot be shown there).
  environment.systemPackages = with pkgs; [
    gnomeExtensions.appindicator
    gnomeExtensions.kimpanel
  ];

  # Enable the extensions declaratively (docs: install via systemPackages,
  # enable via dconf, since NixOS has no gnome.extensions option anymore).
  home-manager.users.${config.home.userName}.dconf.settings."org/gnome/shell" = {
    enabled-extensions = [
      "appindicatorsupport@rgcjonas.gmail.com"
      "kimpanel@kde.org"
    ];
  };
}
