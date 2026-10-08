{ ... }:
{
  flake.aspects."user.nixos" = {
    nixos = {
      users.users.nixos.extraGroups = [ "dialout" ];

      home-manager.users.nixos = {
        home.stateVersion = "26.05";
        xdg.enable = true;

        home.file.".profile".text = ''
          if [ -n "$BASH_VERSION" ]; then
            if [ -f "$HOME/.bashrc" ]; then
              . "$HOME/.bashrc"
            fi
          fi
        '';
      };
    };
  };
}
