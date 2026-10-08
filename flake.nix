{
  description = "infra-v2: NixOS + home-manager (aspect-oriented)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree";
    flake-aspects.url = "github:denful/flake-aspects";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      imports = [
        inputs.flake-aspects.flakeModule
        inputs.flake-parts.flakeModules.modules
        (inputs.import-tree ./aspects)
        (inputs.import-tree ./users)
        (inputs.import-tree ./hosts)
      ];
    };
}
