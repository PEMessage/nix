# ime: Chinese input method (Fcitx 5) for the Wayland desktop.
{ config, lib, pkgs, inputs, ... }:

let
  # macOS Sonoma Dark theme from the non-flake fcitx5-themes-candlelight repo.
  candlelight = pkgs.linkFarm "fcitx5-themes-candlelight" {
    "share/fcitx5/themes/macOS-dark" = "${inputs.fcitx5-themes-candlelight}/macOS-dark";
  };
  # Ori theme from the non-flake Ori-fcitx5 repo.
  ori-theme = pkgs.linkFarm "fcitx5-ori-theme" {
    "share/fcitx5/themes/OriDark" = "${inputs.fcitx5-ori-theme}/OriDark";
    "share/fcitx5/themes/OriLight" = "${inputs.fcitx5-ori-theme}/OriLight";
  };
in
{
  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5 = {
      # GNOME (mutter) does not implement zwp_input_method_v2: GNOME Shell
      # talks to Fcitx over the IBus D-Bus protocol (fcitx5 is built with its
      # ibus frontend) and Qt/GTK Wayland apps use text-input-v3. The NixOS
      # module suppresses the toolkit IM env vars (GTK_IM_MODULE/QT_IM_MODULE)
      # when waylandFrontend is true, which XWayland apps need on GNOME — so
      # only use the Wayland frontend on compositors that implement
      # input_method_v2 (e.g. niri).
      waylandFrontend = !config.services.desktopManager.gnome.enable;
      addons = with pkgs; [
        qt6Packages.fcitx5-chinese-addons
        fcitx5-fluent
        candlelight
        ori-theme
        (fcitx5-rime.override {
         rimeDataPkgs = [
         pkgs.rime-ice
         ];
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
          # "Theme" = "macOS-dark";
          "Theme" = "OriDark";
        };
      };
    };
  };

  environment.systemPackages = with pkgs.qt6Packages; [
    fcitx5-configtool
  ];

  # sessionVariables reach the greetd session via pam_env (plain
  # environment.variables only land in /etc/profile).
  environment.sessionVariables = {
    # XIM bridge for X11/XWayland applications.
    XMODIFIERS = "@im=fcitx";
    # Qt 6.8.2+ implements text-input-v3, so use the compositor path first
    # and fall back to Fcitx; Qt5 (XWayland) uses QT_IM_MODULE=fcitx set by
    # the NixOS module.
    QT_IM_MODULES = "wayland;fcitx";
  };

  # Rime's default.custom.yaml lives in the user data dir
  # (~/.local/share/fcitx5/rime), so manage it via home-manager. home-manager's
  # NixOS module is already imported by os/modules/home.nix, so this
  # can stay in the same file.
  home-manager.sharedModules = [
    (
      { ... }:
      {
        home.file.".local/share/fcitx5/rime/default.custom.yaml" = {
          text = ''
            patch:
              __include: rime_ice_suggestion:/
              schema_list:
                - schema: double_pinyin_mspy
                - schema: rime_ice
              menu:
                page_size: 8
          '';
        };
      }
    )
  ];

  # On GNOME the XDG autostart file ships with the package
  # (etc/xdg/autostart/org.fcitx.Fcitx5.desktop), so no explicit service is
  # needed. This was only required on niri, which runs no XDG autostart:
  # systemd.user.services.fcitx5-daemon = {
  #   description = "Fcitx5 input method service";
  #   wantedBy = [ "graphical-session.target" ];
  #   partOf = [ "graphical-session.target" ];
  #   after = [ "graphical-session.target" ];
  #   serviceConfig = {
  #     Type = "simple";
  #     ExecStart = "${lib.getExe pkgs.fcitx5}";
  #     Restart = "on-failure";
  #   };
  # };
}
