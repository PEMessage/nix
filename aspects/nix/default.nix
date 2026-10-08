{ ... }:
{
  flake.aspects.nix = {
    nixos =
      { config, ... }:
      {
        nixpkgs.config.allowUnfree = true;

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
