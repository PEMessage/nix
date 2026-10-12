{ ... }:
{
  flake.aspects.icons = {
    nixos =
      { pkgs, ... }:
      {
        # Local meta themes (niri/_package/link-icon-theme) that ship no icons
        # and only declare fallback chains, one per mode:
        #   LinkDark  -> Papirus-Dark -> breeze-dark -> Adwaita -> hicolor
        #   LinkLight -> Papirus      -> breeze      -> Adwaita -> hicolor
        # The package propagates the three real themes into the environment, so
        # listing it alone is enough. DMS selects the right one per mode.
        environment.systemPackages = [
          (pkgs.callPackage ./_package/link-icon-theme.nix { })
        ];
      };
  };
}
