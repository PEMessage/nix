{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
in
{
  imports = [
    ./modules/home-manager.nix
  ];

  config = {
    environment.systemPackages =
      with pkgs;
      [
        git
        vim
        which
        python3
        wget

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
      ]
      ++ [
        # tmux: latest from nixpkgs-unstable
        unstable.tmux
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

    nixpkgs.config.allowUnfree = true;
  };
}
