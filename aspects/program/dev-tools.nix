{ config, ... }:
{
  flake.aspects.dev-tools = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          # c/c++
          gdb

          # rust
          rustc
          cargo

          # bun
          bun
        ];

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
