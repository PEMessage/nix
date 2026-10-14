{ ... }:
{
  flake.aspects.icons = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [
          (pkgs.callPackage ./_package/link-icon-theme.nix { })
        ];
      };
  };
}
