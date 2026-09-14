# x: desktop (X11 / Wayland) system configuration.
# Enabled on real desktop hosts, not on WSL.
{ config, lib, pkgs, options, inputs, ... }:
{
  imports = [
    ./modules/niri
    # ./modules/gnome
    # ./modules/kde
    ./modules/app.nix
    inputs.nix-index-database.nixosModules.default

    # WSLg already provides the input method path, and Fcitx5's clipboard/X11
    # selection traffic is a known trigger for WSLg's weston clipboard crash
    # (microsoft/wslg#1407), so drop ime.nix on WSL hosts. A plain
    # `lib.optional (config.wsl.enable or false) ...` in `imports` is not
    # allowed (config is not available there -> infinite recursion), so the
    # module is applied here and gated with mkIf instead.
    (lib.mkIf (!(config.wsl.enable or false)) (
      import ./modules/ime.nix { inherit config lib pkgs inputs; }
    ))
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

  programs.nix-index-database.enable = true;

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
