# niri: scrollable-tiling Wayland compositor (replaces GNOME on desktop hosts).
{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    inputs.noctalia.nixosModules.default
  ];

  programs.noctalia = {
    enable = true;
    # Enables NetworkManager, Bluetooth, UPower, and a power profile service.
    recommendedServices.enable = true;
  };
  nix.settings = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [ "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" ];
  };

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
