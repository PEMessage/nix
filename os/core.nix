{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./modules/herdr
  ];

  config = {

    herdr.enable = true;

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 21d";
    };
    nix.optimise.automatic = true;
    nixpkgs.config.allowUnfree = true;

    # Expose nixpkgs-unstable as pkgs.unstable everywhere (NixOS + home-manager).
    # Thanks to: https://github.com/cole-glotfelty/nixcfg.git
    nixpkgs.overlays = [
      (final: _prev: {
        unstable = import inputs.nixpkgs-unstable {
          system = final.stdenv.hostPlatform.system;
          config.allowUnfree = true;
        };
      })
    ];

    environment.systemPackages =
      with pkgs;
      [
        git
        vim
        which
        python3
        wget
        bc

        # build
        gcc
        gnumake
        binutils
        autoconf
        automake

        # system
        kbd

        # zip
        _7zz
        unzip

        # modern unix
        neovim
        fzf
        ripgrep
        tealdeer
      ]
      ++ [
        # tmux: latest from nixpkgs-unstable
        pkgs.unstable.tmux
      ];
    environment.localBinInPath = true;


    #Error during "tree-sitter build": Could not start dynamically linked executable: tree-sitter
    #NixOS cannot run dynamically linked executables intended for generic
    #linux environments out of the box. For more information, see:
    #https://nix.dev/permalink/stub-ld
    programs.nix-ld.enable = true;

    # Shell
    # ===================================
    programs.bash.enable = true;

    # will auto enable nix-community/nix-zsh-completions
    programs.zsh.enable = true;
    environment.shells = [ pkgs.zsh ];
    users.defaultUserShell = pkgs.zsh;

    # appimage support
    # ===================================
    programs.appimage.enable = true;
    programs.appimage.binfmt = true;

    # home-manager: inject this feature's home config into every home user.
    home-manager.sharedModules = [
      (
        { ... }:
        {
          home.stateVersion = "26.05";

          home.file.".profile".text = ''
            # if running bash
            if [ -n "$BASH_VERSION" ]; then
              # include .bashrc if it exists
              if [ -f "$HOME/.bashrc" ]; then
              . "$HOME/.bashrc"
              fi
            fi
          '';
        }
      )
    ];

  };
}
