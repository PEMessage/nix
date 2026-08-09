# ime: Chinese input method (Fcitx 5) for the Wayland desktop.
{ config, lib, pkgs, ... }:
{
  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5 = {
      # niri implements text-input-v3 and zwp_input_method_v2, so Fcitx runs
      # with its Wayland frontend: no toolkit IM env vars are needed and the
      # compositor positions the candidate popup correctly.
      waylandFrontend = true;
      # Thanks to https://zhuanlan.zhihu.com/p/1963358188226183647
      addons = with pkgs; [
        qt6Packages.fcitx5-chinese-addons
        fcitx5-fluent
        (fcitx5-rime.override {
         rimeDataPkgs = [
         pkgs.rime-ice
         ];
         })
        librime
      ];
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
    # Qt 6.7–6.8.1 needs an explicit fallback chain to reach Fcitx over
    # text-input-v3; Qt5 (XWayland) falls back to the bundled Qt IM module.
    QT_IM_MODULES = "wayland;fcitx";
  };

  # Rime's default.custom.yaml lives in the user data dir
  # (~/.local/share/fcitx5/rime), so manage it via home-manager. home-manager's
  # NixOS module is already imported by os/modules/home-manager.nix, so this
  # can stay in the same file.
  home-manager.users.${config.home.userName}.home.file.".local/share/fcitx5/rime/default.custom.yaml" = {
    text = ''
      patch:
        __include: rime_ice_suggestion:/
        schema_list:
          - schema: rime_ice
          - schema: double_pinyin_mspy
        menu:
          page_size: 8
    '';
  };

  # With the Wayland frontend nothing dbus-activates Fcitx, so start it
  # explicitly with the graphical session.
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
