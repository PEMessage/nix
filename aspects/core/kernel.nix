# Security-critical updates from the separately pinned `nixpkgs-small` input
# (flake.nix). Only the kernel is taken from it; the rest keeps using `pkgs`.
#
# Not in `core`: WSL boots the Windows kernel and must not pull this in.
{ inputs, ... }:
{
  flake.aspects.kernel = {
    nixos =
      { pkgs, ... }:
      let
        kernelPkgs = import inputs.nixpkgs-small {
          system = pkgs.stdenv.hostPlatform.system;
        };
      in
      {
        # Pin the LTS line; bare `linuxPackages` follows the branch default.
        boot.kernelPackages = kernelPkgs.linuxPackages_6_18;
      };
  };
}
