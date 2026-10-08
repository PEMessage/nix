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

        # Plain value (priority 100) beats the mkDefault bash set by
        # programs.bash.enable. A server host can override with
        # `lib.mkForce pkgs.bashInteractive`.
        users.defaultUserShell = pkgs.zsh;
      };
  };
}
