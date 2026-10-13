{ ... }:
{
  flake.aspects.icons = {
    nixos =
      { pkgs, ... }:
      {
        # Meta theme (niri/_package/link-icon-theme): no icons, only the chain
        # LinkIcons -> Papirus-Dark -> breeze-dark -> Adwaita -> hicolor. It
        # propagates the real themes, so listing it alone suffices; DMS selects it.
        environment.systemPackages = [
          (pkgs.callPackage ./_package/link-icon-theme.nix { })
        ];
      };
  };
}
