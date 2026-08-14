{ config, lib, pkgs, inputs, ... }:
{
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

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
