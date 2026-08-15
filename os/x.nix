# x: desktop (X11 / Wayland) system configuration.
# Enabled on real desktop hosts, not on WSL.
{ config, pkgs, options, ... }:
{
  imports = [
    # ./modules/niri.nix
    ./modules/gnome.nix
    ./modules/ime.nix
    ./modules/app.nix
  ];

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  programs.nix-ld = {
    libraries = with pkgs; [
      # fonts
      fontconfig
      freetype

      glib
      dbus
      libGL
      libxcb

      # wayland
      wayland
      wayland-protocols

      # keyboard
      libxkbcommon
    ];
  };

  # enable uinput for remote desktop
  hardware.uinput.enable = true;
}
