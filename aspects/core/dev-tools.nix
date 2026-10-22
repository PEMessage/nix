{ config, inputs, ... }:
{
  flake.aspects.dev-tools = {
    nixos =
      { pkgs, ... }:
      {
        imports = [ inputs.nix-index-database.nixosModules.default ];

        environment.systemPackages = with pkgs; [
          # c/c++
          gdb
          git-extras

          # rust
          rustc
          cargo

          # bun
          bun

          # build
          just

          # secrets
          (symlinkJoin {
            name = "infisical";
            paths = [ unstable.infisical ];
            nativeBuildInputs = [ makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/infisical \
                --set-default INFISICAL_DISABLE_UPDATE_CHECK true
            '';
          })
        ];

        # Replace uv to unstable one
        nixpkgs.overlays = [
          (final: prev: {
            uv = pkgs.unstable.uv;
          })
        ];

        programs.nix-index-database = {
          enable = true;
          comma.enable = true;
        };
        # keep the database (nix-locate) but drop the "command not found"
        # suggestions the shells would print.
        programs.nix-index = {
          enableBashIntegration = false;
          enableZshIntegration = false;
          enableFishIntegration = false;
        };

        # direnv: the hook goes into /etc/zshrc (programs.zsh.interactiveShellInit),
        programs.direnv = {
          enable = true;
          # silent = true; # hide the env-diff spam on every load
          nix-direnv.enable = true;
        };

        home-manager.sharedModules = [ config.flake.modules.homeManager.dev-tools ];
      };

    homeManager =
      { pkgs, ... }:
      {
        # `programs.pnpm` only exists on home-manager master; import that single
        # module file instead of moving the whole user base off release-26.05.
        imports = [ "${inputs.home-manager-unstable}/modules/programs/pnpm.nix" ];

        home.packages = with pkgs; [
          gh
          nixfmt
          tree-sitter
        ];

        programs.pnpm.enable = true;

        home.file.".peprofile".text = ''
          "$(command -v bun)" > /dev/null && export PATH="$HOME/.bun/bin:$PATH"
        '';
      };
  };
}
