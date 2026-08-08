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
    environment.systemPackages = with pkgs; [
      git
      vim
      which
      python3
      tmux

      # build
      gcc
      gnumake
      binutils
      autoconf
      automake

      # modern unix
      neovim
      fzf
      ripgrep
      tealdeer
    ];

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    #Error during "tree-sitter build": Could not start dynamically linked executable: tree-sitter
    #NixOS cannot run dynamically linked executables intended for generic
    #linux environments out of the box. For more information, see:
    #https://nix.dev/permalink/stub-ld
    programs.nix-ld.enable = true;

    programs.bash.enable = true;

    # will auto enable nix-community/nix-zsh-completions
    programs.zsh.enable = true;
    environment.shells = [ pkgs.zsh ];
    users.defaultUserShell = pkgs.zsh;

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
