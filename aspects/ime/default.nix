{ config, inputs, ... }:
let
  fp = config;
in
{
  flake.aspects.ime = {
    nixos =
      { config, lib, pkgs, ... }:
      let
        # macOS Sonoma Dark theme from the non-flake candlelight repo
        candlelight = pkgs.linkFarm "fcitx5-themes-candlelight" {
          "share/fcitx5/themes/macOS-dark" = "${inputs.fcitx5-themes-candlelight}/macOS-dark";
        };
        # Ori theme from the non-flake Ori-fcitx5 repo
        ori-theme = pkgs.linkFarm "fcitx5-ori-theme" {
          "share/fcitx5/themes/OriDark" = "${inputs.fcitx5-ori-theme}/OriDark";
          "share/fcitx5/themes/OriLight" = "${inputs.fcitx5-ori-theme}/OriLight";
        };
      in
      # WSLg already provides the input path, and fcitx's clipboard/X11
      # traffic is a known trigger for the WSLg weston clipboard crash.
      lib.mkIf (!(config.wsl.enable or false)) {
        i18n.inputMethod = {
          type = "fcitx5";
          enable = true;
          fcitx5 = {
            # only use the Wayland frontend on compositors implementing
            # input_method_v2 (e.g. niri), not GNOME.
            waylandFrontend = !config.services.desktopManager.gnome.enable;
            addons = with pkgs; [
              qt6Packages.fcitx5-chinese-addons
              fcitx5-fluent
              candlelight
              ori-theme
              (fcitx5-rime.override {
                rimeDataPkgs = [ pkgs.rime-ice ];
              })
              librime
            ];
            settings = {
              inputMethod = {
                GroupOrder."0" = "Default";
                "Groups/0" = {
                  Name = "Default";
                  "Default Layout" = "us";
                  DefaultIM = "keyboard-us";
                };
                "Groups/0/Items/0".Name = "keyboard-us";
                "Groups/0/Items/1".Name = "rime";
              };
              addons.classicui.globalSection = {
                "Vertical Candidate List" = false;
                "Theme" = "OriDark";
              };
            };
          };
        };

        environment.systemPackages = with pkgs.qt6Packages; [
          fcitx5-configtool
        ];

        # sessionVariables reach the greetd session via pam_env
        environment.sessionVariables = {
          XMODIFIERS = "@im=fcitx";
          QT_IM_MODULES = "wayland;fcitx";
        };

        home-manager.sharedModules = [ fp.flake.modules.homeManager.ime ];
      };

    homeManager = {
      home.file.".local/share/fcitx5/rime/default.custom.yaml".text = ''
        patch:
          __include: rime_ice_suggestion:/
          schema_list:
            - schema: double_pinyin_mspy
            - schema: rime_ice
          menu:
            page_size: 8
      '';
    };
  };
}
