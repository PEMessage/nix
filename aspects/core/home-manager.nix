{ inputs, ... }:
{
  flake.aspects.home-manager = {
    nixos = {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = { inherit inputs; };
      };
    };

    homeManager = {
      home.stateVersion = "26.05";
      xdg.enable = true;
    };
  };
}
