{ lib, pkgs, ... }:
{
  # Fluent (Windows 11 style) GTK/Shell theme + Fluent icons.
  environment.systemPackages = with pkgs; [
    gnomeExtensions.user-themes
    fluent-gtk-theme
    fluent-icon-theme
  ];

  home-manager.sharedModules = [
    (
      { ... }:
      {
        dconf.settings = {
    "org/gnome/shell" = {
      enabled-extensions = lib.mkBefore [ pkgs.gnomeExtensions.user-themes.extensionUuid ];
    };

    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Fluent-Dark";
      icon-theme = "Fluent-dark";
    };

    "org/gnome/shell/extensions/user-theme" = {
      name = "Fluent-Dark";
    };
  }
      )
    ];
}
