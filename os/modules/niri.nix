# niri: scrollable-tiling Wayland compositor (replaces GNOME on desktop hosts).
{ config, lib, pkgs, ... }:
{
  programs.niri.enable = true;
  environment.systemPackages = with pkgs; [
    fuzzel
  ];

  # Lightweight login manager with autologin straight into niri.
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.niri}/bin/niri-session";
        user = config.home.userName;
      };
    };
  };

  # No display manager needed, greetd takes over the login screen.
  services.displayManager.enable = false;
}
