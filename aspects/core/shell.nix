{ config, ... }:
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

        home-manager.sharedModules = [ config.flake.modules.homeManager.shell ];
      };

    homeManager =
      { config, ... }:
      {

        programs.zsh.enable = true;
        # Mirror home-manager's own shell wiring without enabling its shell
        # modules, because chezmoi owns ~/.zshrc and ~/.bashrc and
        # `programs.zsh` / `programs.bash` would take those files over. Same
        # files, same contents as the modules would write:
        #   ~/.zshenv       -> read by every zsh, interactive or not
        #   ~/.bash_profile -> login bash; bridges to ~/.profile and ~/.bashrc
        #   ~/.profile      -> login sh/bash; session variables only
        home.file.".zshenv".text = ''
          . ${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh
        '';

        home.file.".bash_profile".text = ''
          # include .profile if it exists
          [[ -f ~/.profile ]] && . ~/.profile

          # include .bashrc if it exists
          [[ -f ~/.bashrc ]] && . ~/.bashrc
        '';

        home.file.".profile".text = ''
          . ${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh
        '';
      };
  };
}
