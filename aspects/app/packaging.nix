{ ... }:
{
  flake.aspects.flatpak = {
    nixos.services.flatpak.enable = true;
  };

  flake.aspects.appimage = {
    nixos = {
      programs.appimage.enable = true;
      programs.appimage.binfmt = true;
    };
  };
}
