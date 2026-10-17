{ config, inputs, ... }:
let
  fp = config;
in
{
  flake.aspects.piri = {
    nixos =
      { ... }:
      {
        imports = [ inputs.piri.nixosModules.default ];

        # systemd user service bound to graphical-session.target. Upstream
        # leaves enableDefaultPath off on purpose: the unit then inherits the
        # PATH niri-session imported into the user manager, which is what
        # plugin-spawned commands need.
        services.piri.enable = true;

        home-manager.sharedModules = [ fp.flake.modules.homeManager.piri ];
      };

    homeManager =
      { ... }:
      {
        # Only the daemon runs: every piri plugin is opt-in and defaults to
        # off. Flip a flag to true and rebuild to enable that plugin; piri
        # hot-reloads the file in place.
        xdg.configFile."niri/piri.toml".text = ''
          [piri.plugins]
          scratchpads = false
          empty = false
          window_rule = false
          singleton = false
          window_order = false
          swallow = false
          workspace_rule = false
          mark = false
          sticky = false
        '';
      };
  };
}
