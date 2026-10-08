{ config, inputs, ... }:
{
  flake.aspects.home-manager = {
    nixos = {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = { inherit inputs; };
        sharedModules = [ config.flake.modules.homeManager.home-manager ];
      };
    };

    homeManager = {
      home.stateVersion = "26.05";
      xdg.enable = true;
    };
  };
}
