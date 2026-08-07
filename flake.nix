{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs:
    let
      inherit (inputs) nixpkgs;
    in
    {
      nixosConfigurations.wsl = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/wsl/configuration.nix
          ./modules/core/core.nix
          ./modules/core/nixos.nix
          ./modules/core/modern_unix.nix
          ./modules/core/home-manager-integration.nix
          ({ config, ... }: {
            home = {
              userName = config.wsl.defaultUser;
              configFile = ./home.nix; # 这里明确相对于 flake.nix
            };
          })
        ];
      };
    };
}
