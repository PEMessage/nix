{ ... }:
{
  flake.aspects.shell = {
    nixos =
      { pkgs, ... }:
      {
        programs.bash.enable = true;
        programs.zsh.enable = true; # pulls in nix-zsh-completions

        environment.shells = [ pkgs.zsh ];
        environment.localBinInPath = true;

        # Plain value (100) beats the mkDefault bash from programs.bash.enable;
        # a server host overrides with `lib.mkForce pkgs.bashInteractive`.
        users.defaultUserShell = pkgs.zsh;
      };

    homeManager = {
      home.file.".profile".text = ''
        if [ -n "$BASH_VERSION" ]; then
          if [ -f "$HOME/.bashrc" ]; then
            . "$HOME/.bashrc"
          fi
        fi
      '';
    };
  };
}
