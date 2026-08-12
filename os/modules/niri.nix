# niri: scrollable-tiling Wayland compositor (replaces GNOME on desktop hosts).
{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    inputs.noctalia.nixosModules.default
    inputs.niri.nixosModules.niri
  ];

  programs.noctalia = {
    enable = true;
    # recommendedServices enables NetworkManager, Bluetooth, UPower, and a
    # power profile service. On WSL hosts these are both useless (WSL2 does
    # not expose Wi-Fi/Bluetooth hardware to Linux) and harmful:
    #
    #   recommendedServices.enable = true
    #     -> noctalia module sets networking.networkmanager.enable = true
    #     -> nixpkgs networkmanager module (networkmanager.nix) also sets
    #        networking.wireless.enable = true to run wpa_supplicant over D-Bus
    #     -> the networking.wireless module generates wpa_supplicant.service
    #        with a hardcoded BindPaths=/dev/rfkill (plus DeviceAllow=/dev/rfkill)
    #        inside a PrivateDevices sandbox
    #     -> /dev/rfkill does not exist in WSL (no radio hardware), so systemd
    #        fails to set up the mount namespace: status 226/NAMESPACE
    #     -> wpa_supplicant.service fails and `nixos-rebuild switch` exits 4
    #
    # Hence: only enable these services on non-WSL hosts.
    # `config.wsl.enable or false` also keeps hosts that never import the
    # nixos-wsl module (e.g. pro830) from failing to evaluate.
    recommendedServices.enable = !(config.wsl.enable or false);
  };

  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

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

  environment.systemPackages = with pkgs; [
    fuzzel
    swaylock
  ];
}
