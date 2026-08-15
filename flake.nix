{
  description = "NixOS / home-manager configuration";
  nixConfig = rec {
    extra-substituters = [
      "https://noctalia.cachix.org"
      "https://niri.cachix.org"
    ];
    extra-trusted-substituters = extra-substituters;
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs"; # this line is optional, prevents downloading two versions of nixpkgs but disables cache
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gnome-rounded-blur = {
      url = "github:Klazkin/nix-gnome-rounded-blur";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  # groups: core (have to) / dev / gui (shared by wsl and x) / x (desktop)
  outputs = inputs: {
    nixosConfigurations.wsl = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/wsl/configuration.nix
        ./os/core.nix
        ./os/dev.nix
        ./os/gui.nix
        ./os/x.nix
        ({ config, ... }: {
          home.userName = config.wsl.defaultUser;
          home.groupModules = [
            ./home/core.nix
            ./home/dev.nix
            ./home/gui.nix
            ./home/x.nix
          ];
        })
      ];
    };

    nixosConfigurations.pro830 = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/pro830/configuration.nix
        ./os/core.nix
        ./os/dev.nix
        ./os/gui.nix
        ./os/x.nix
        ({ config, ... }: {
          home.userName = "pem";
          home.groupModules = [
            ./home/core.nix
            ./home/dev.nix
            ./home/gui.nix
            ./home/x.nix
          ];
        })
      ];
    };
  };
}
