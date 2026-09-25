{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    # ./modules/herdr
    ./modules/script
  ];

  config = {

    # herdr.enable = true;

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
    # See: https://nixos-and-flakes.thiscute.world/zh/nix-store/add-binary-cache-servers
    nix.settings.trusted-users = [ "root" "pem" ];

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
        #kernel
        kmod

        # utils
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
        openssl
        # temporarily open firewall ports at runtime, e.g.
        #   nixos-firewall-tool open tcp 12345
        nixos-firewall-tool

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

    # uv's openssl need CA file at /etc/ssl/cert.pem or /ets/ssl/certs
    # NixOS provide following:
    #  - /etc/ssl/certs/ca-certificates.crt ← Debian/Arch/Gentoo
    #  - /etc/ssl/certs/ca-bundle.crt ← Old NixOS
    #  - /etc/pki/tls/certs/ca-bundle.crt ← CentOS/Fedora
    # NixOS intentionally ships only a CA bundle (CAfile), not a c_rehash
    # directory (CApath): https://github.com/NixOS/nixpkgs/pull/12748

    # Source: https://discourse.nixos.org/t/fix-ssl-sslcertverificationerror-with-uvs-standalone-python/71138
    # source uses security.pki.caBundle, the read-only option from
    # nixpkgs nixos/modules/security/ca.nix (the final CA bundle), so custom
    # certs from security.pki.* are included automatically.
    environment.etc."ssl/cert.pem".source = config.security.pki.caBundle;


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
    # zsh by default; headless servers (hostname starts with "vps") use bash.
    # This plain value (priority 100) wins over the mkDefault bash that
    # programs.bash provides, so no mkForce is needed.
    users.defaultUserShell =
      if lib.hasPrefix "vps" config.networking.hostName
      then pkgs.bashInteractive
      else pkgs.zsh;

    # home-manager: inject this feature's home config into every home user.
    home-manager.sharedModules = [
      (
        { ... }:
        {
          home.stateVersion = "26.05";
          xdg.enable = true;

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
