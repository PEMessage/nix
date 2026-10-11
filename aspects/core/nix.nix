{ inputs, ... }:
{
  flake.aspects.nix = {
    nixos =
      { config, ... }:
      {
        nixpkgs.config.allowUnfree = true;

        nixpkgs.overlays = [
          # Overlay args: `final` = pkgs with all overlays applied (here we
          # only read its `system`); `prev` = pkgs before this overlay
          # (unused, hence the `_` prefix).
          (final: _prev: {
            unstable = import inputs.nixpkgs-unstable {
              system = final.stdenv.hostPlatform.system;
              config.allowUnfree = true;
            };
          })
        ];

        nix.settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          trusted-users = [ "@wheel" ];
        };

        nix.gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 21d";
        };
        nix.optimise.automatic = true;

        programs.nix-ld.enable = true;

        environment.etc."ssl/cert.pem".source = config.security.pki.caBundle;
      };
  };
}
