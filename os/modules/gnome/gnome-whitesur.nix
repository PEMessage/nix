{ lib, pkgs, ... }:
{
  # WhiteSur (macOS Big Sur style) GTK/Shell theme + WhiteSur icons.
  # macOS-style window buttons (close left) are handled by GNOME itself:
  # set "org.gnome.desktop.wm.preferences" button-layout = "close,minimize,maximize:";
  # (gnome/default.nix currently forces ":minimize,maximize,close").
  environment.systemPackages = with pkgs; [
    gnomeExtensions.user-themes
    whitesur-gtk-theme
    whitesur-icon-theme
    whitesur-cursors
  ];

  home-manager.sharedModules = [
    (
      { ... }:
      {
        dconf.settings = {
    "org/gnome/shell" = {
      enabled-extensions = lib.mkBefore [ pkgs.gnomeExtensions.user-themes.extensionUuid ];
    };

    # mkForce so this module wins over gnome-fluent.nix when both are imported.
    "org/gnome/desktop/interface" = {
      color-scheme = lib.mkForce "prefer-dark";
      gtk-theme = lib.mkForce "WhiteSur-Dark";
      icon-theme = lib.mkForce "WhiteSur-dark";
      # Fix box cursor after switching from KDE: dconf was left pointing at
      # "breeze_cursors", which is no longer installed.
      cursor-theme = lib.mkForce "WhiteSur-cursors";
      cursor-size = lib.mkForce 24;
    };

    "org/gnome/shell/extensions/user-theme" = {
      name = lib.mkForce "WhiteSur-Dark";
    };
  }
      )
    ];
}
