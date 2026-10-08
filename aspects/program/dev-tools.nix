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

          # rust
          rustc
          cargo

          # bun
          bun
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

        home-manager.sharedModules = [ config.flake.modules.homeManager.dev-tools ];
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          gh
          nixfmt
          tree-sitter
        ];

        home.file.".peprofile".text = ''
          "$(command -v bun)" > /dev/null && export PATH="$HOME/.bun/bin:$PATH"
        '';
      };
  };
}
