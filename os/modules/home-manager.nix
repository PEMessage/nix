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

    groupModules = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      description = "Home-manager modules selected by the host profile groups.";
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
      users.${cfg.userName} = {
        imports = cfg.groupModules;
      };
      extraSpecialArgs = cfg.extraSpecialArgs;
    };
  };
}
