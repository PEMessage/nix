{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.home;
in
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  options.home = {
    userName = lib.mkOption {
      type = lib.types.str;
      description = "System username for home-manager.";
    };

    configFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the home.nix configuration file.";
    };

    extraSpecialArgs = lib.mkOption {
      type = lib.types.attrs;
      default = { inherit inputs; };
    };
  };

  config = {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.${cfg.userName} = import cfg.configFile;
      extraSpecialArgs = cfg.extraSpecialArgs;
    };
  };
}
