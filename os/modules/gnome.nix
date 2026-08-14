{ config, lib, pkgs, inputs, ... }:
{
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # AppIndicator tray icons (fcitx5 status icon etc.)
  environment.systemPackages = with pkgs; [ gnomeExtensions.appindicator ];

  # Enable the extension declaratively (docs: install via systemPackages,
  # enable via dconf, since NixOS has no gnome.extensions option anymore).
  home-manager.users.${config.home.userName}.dconf.settings."org/gnome/shell" = {
    enabled-extensions = [ "appindicatorsupport@rgcjonas.gmail.com" ];
  };
}
