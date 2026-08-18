{
  description = "NixOS / home-manager configuration";
  nixConfig = rec {
    # Thanks https://github.com/RazYang/dotfiles/blob/443186a01817af0062ef331b628c1f2fd281d5c1/flake.nix
    experimental-features = [
      "flakes"
      "nix-command"
    ];
    extra-substituters = [
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://nix-community.cachix.org"

      "https://noctalia.cachix.org"
      "https://niri.cachix.org"
    ];
    extra-trusted-substituters = extra-substituters;
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
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
    plasma-manager = {
      url = "github:nix-community/plasma-manager/trunk";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs"; # this line is optional, prevents downloading two versions of nixpkgs but disables cache
    };
    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs"; # this line is optional, prevents downloading two versions of nixpkgs but disables cache
    };
    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dsearch = {
      url = "github:AvengeMedia/danksearch";
      inputs.nixpkgs.follows = "nixpkgs";
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
