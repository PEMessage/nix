# gradle - keep the rich console usable with a nixpkgs JDK.
#
# `fix-gradle-console` patches the native libraries the Gradle wrapper
# extracts into ~/.gradle/native (missing RUNPATH, see the package header).
# Run it once after a wrapper upgrade or a nixpkgs update; there is no daemon
# or hook, because the cache is only populated when Gradle actually runs.
{ config, ... }:
{
  flake.aspects.gradle = {
    nixos = _: {
      home-manager.sharedModules = [ config.flake.modules.homeManager.gradle ];
    };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          (pkgs.callPackage ./_package/fix-gradle-console.nix { })
        ];
      };
  };
}
