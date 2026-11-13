{
  description = "infra-v2: NixOS + home-manager (aspect-oriented)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # Security-critical updates (currently the kernel); not followed by any
    # other input, so a CVE fix does not re-pin userland.
    nixpkgs-small.url = "github:nixos/nixpkgs?ref=nixos-26.05-small";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Out-of-tree Android binder for the WSL kernel. `nixpkgs` is only used at
    # runtime by its module; the .ko is built by its own pinned nixpkgs-build.
    wsl-binder = {
      url = "github:PEMessage/wsl-binder";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Only used for the odd module that has not landed in release-26.05 yet
    # (currently `programs/pnpm.nix`); never imported as a whole module set.
    # Follows nixpkgs-unstable, the branch this home-manager master targets.
    home-manager-unstable = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms = {
      url = "github:duxlabs-dev/dux-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms-plugin-registry = {
      url = "github:duxlabs-dev/dux-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dsearch = {
      url = "github:duxlabs-dev/dux-search";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    apollo-flake = {
      url = "github:angelus788/apollo-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fcitx5-themes-candlelight = {
      url = "github:thep0y/fcitx5-themes-candlelight";
      flake = false;
    };
    fcitx5-ori-theme = {
      url = "github:Reverier-Xu/Ori-fcitx5";
      flake = false;
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree";
    flake-aspects.url = "github:denful/flake-aspects";
  };

  nixConfig = {
    extra-substituters = [
      "https://mirrors.cernet.edu.cn/nix-channels/store"
      "https://nix-community.cachix.org"
      "https://niri.cachix.org"
      "https://github.com/PEMessage/wsl-binder/releases/latest/download"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "wsl-binder-1:+J56oPBLvItpSBAJ3RBDy6G9vxzPEP8VwXqJ6aIo2sI="
    ];
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      # Expose `self.debug.options` so nixd can resolve flake-parts option
      # attrpaths (`flake.*` / `config.flake.*`). See: https://flake.parts/debug
      debug = true;
      systems = [ "x86_64-linux" ];

      imports = [
        inputs.flake-aspects.flakeModule
        inputs.flake-parts.flakeModules.modules
        (inputs.import-tree ./aspects)
        (inputs.import-tree ./users)
        (inputs.import-tree ./profile)
        (inputs.import-tree ./hosts)
      ];
    };
}
