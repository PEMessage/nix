{ ... }:
{
  flake.aspects.flatpak = {
    nixos.services.flatpak.enable = true;
  };

  flake.aspects.appimage = {
    nixos =
      { config, ... }:
      {
        programs.appimage.enable = true;
        programs.appimage.binfmt = !(config.wsl.enable or false);
      };
  };
}
