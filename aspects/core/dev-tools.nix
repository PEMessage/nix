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
      { config, pkgs, ... }:
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

        # `bun add -g` installs into $BUN_INSTALL/bin (~/.bun/bin) and
        # home-manager's programs.bun does not touch PATH or BUN_INSTALL, so
        # wire it up as session variables. This replaces the old
        # ~/.peprofile guard: session variables only started reaching the shell
        # once ~/.zshenv sourced hm-session-vars.sh.
        home.sessionVariables.BUN_INSTALL = "${config.home.homeDirectory}/.bun";
        home.sessionPath = [ "${config.home.homeDirectory}/.bun/bin" ];
      };
  };
}
