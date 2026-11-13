# Hardware brightness and DDC/CI power control for the RTK panel on wks-revo.
#
# The panel is only reachable over the DisplayPort AUX i2c adapter (bus 14,
# "AMDGPU DM aux hw bus 3"). It answers VCP 0x10 (brightness, max 100) and
# 0xD6 (power mode) but NAKs a large fraction of reads and sometimes reports a
# failed write that did apply; panelctl therefore retries and verifies every
# operation itself (see the header of ./panelctl for the full quirks list).
#
# Dux probes every /dev/i2c-* adapter on its own and, once it finds this panel,
# silently replaces the gamma brightness slider with a DDC device: the screen
# jumps brighter (the gamma dim is reset to 100%) and Dux races ddcutil for
# the bus, which shows up as a stuck slider and "unknown" reads. Keep Dux out
# of DDC so panelctl is the only writer.
{ config, ... }:
let
  fp = config;

  # flake-parts modules get no `pkgs`, so build the wrapper per module system;
  # both halves produce the same derivation.
  mkPanelctl =
    pkgs:
    pkgs.writeShellApplication {
      name = "panelctl";
      runtimeInputs = [
        pkgs.ddcutil
        pkgs.gawk
        pkgs.coreutils
        pkgs.util-linux
      ];
      text = builtins.readFile ./panelctl;
    };
in
{
  flake.aspects.panelctl = {
    nixos =
      { config, pkgs, ... }:
      let
        # Exactly one home-manager user per host; the same trick as the niri
        # aspect uses for greetd.
        userName = builtins.head (builtins.attrNames config.home-manager.users);
      in
      {
        # Loads i2c-dev and installs the udev rule that gives the local seat
        # user a uaccess ACL plus group i2c / mode 0660.
        hardware.i2c.enable = true;

        # SSH sessions are not tied to a seat, so they get no uaccess ACL.
        users.groups.i2c.members = [ userName ];

        environment.systemPackages = [
          pkgs.i2c-tools
          pkgs.ddcutil
          (mkPanelctl pkgs)
        ];

        home-manager.sharedModules = [ fp.flake.modules.homeManager.panelctl ];
      };

    homeManager =
      { lib, ... }:
      {
        # Read by systemd --user at login; niri (and Dux, which it spawns)
        # inherit it. Without this Dux takes the panel over as soon as
        # /dev/i2c-14 exists.
        systemd.user.sessionVariables.DMS_NO_DDC = "1";

        # Local (non-registry) widget plugin. The plugin only queries DDC while
        # its popout is open; the bar pill is just an icon.
        programs.dank-material-shell = {
          managePluginSettings = true;
          plugins.panelCtl = {
            src = ./plugin;
          };
        };

        dux.barConfigs.default.rightWidgets = lib.mkBefore [ "panelCtl" ];

        # The panel is the only display, so turning it off from the bar would
        # otherwise leave no way to switch it back on from the session.
        programs.niri.settings.binds."Mod+Alt+M".action.spawn = [
          "panelctl"
          "power"
          "toggle"
        ];
      };
  };
}
