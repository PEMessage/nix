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
        # home-manager's session variables (PNPM_HOME, XDG_*, every
        # `home.sessionPath` entry) are only sourced by home-manager's *own*
        # shell modules, so enable the zsh one to get ~/.zshenv generated.
        # Its rc files must stay chezmoi's, which needs both of the following:
        #   * dotDir = $HOME: the default is ~/.config/zsh since stateVersion
        #     26.05 + xdg.enable, and that mode exports ZDOTDIR, which makes
        #     zsh read ~/.config/zsh/.zshrc and IGNORE ~/.zshrc;
        #   * disabling the .zshrc entry: the module writes it unconditionally,
        #     so without this it would replace ~/.zshrc with a store symlink.
        # NOTE: with the rc file disabled, home-manager options that end up in
        # it (initContent, shellAliases, completion, syntaxHighlighting, ...)
        # silently have no effect for zsh.
        programs.zsh = {
          enable = true;
          dotDir = config.home.homeDirectory;
        };
        home.file."${config.lib.zsh.dotDirRel}/.zshrc".enable = false;

        # Login bash: bridge to ~/.profile and ~/.bashrc, exactly like
        # home-manager's bash module (not enabled, same chezmoi-owns-rc reason).
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
