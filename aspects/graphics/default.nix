{ ... }:
{
  flake.aspects.graphics = {
    nixos =
      { pkgs, ... }:
      {
        services.xserver.enable = true;
        services.xserver.xkb = {
          layout = "us";
          variant = "";
        };

        # sound via pipewire
        services.pulseaudio.enable = false;
        security.rtkit.enable = true;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
        };

        xdg.portal = {
          enable = true;
          extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        };

        programs.nix-ld.libraries = with pkgs; [
          # fonts
          fontconfig
          freetype

          # base
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

        hardware.uinput.enable = true;
      };
  };
}
