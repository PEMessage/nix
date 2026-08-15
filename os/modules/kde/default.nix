# kde: KDE Plasma 6 desktop (SDDM login + KWin Wayland session).
# Drop-in alternative to ./gnome: swap the import in os/x.nix to use it.
{ config, lib, pkgs, inputs, ... }:
{
  # Display manager
  # ==========================
  services.displayManager.sddm = {
    enable = true;
    autoNumlock = true;
    wayland.enable = true; # KWin login screen
  };
  services.displayManager.autoLogin = {
    enable = true;
    user = config.home.userName;
  };
  services.desktopManager.plasma6.enable = true;

  # Trim default apps (kept: dolphin, kate, konsole, okular, spectacle, ...)
  # ==========================
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    akregator
    dragon
    elisa
    kaddressbook
    kalarm
    kcharselect
    kcolorchooser
    kcontacts
    kdenetwork-filesharing
    kfind
    kgpg
    khelpcenter
    kig
    kmag
    kmail
    kmenuedit
    kmousetool
    kmouth
    kmplot
    kolourpaint
    kompare
    konqueror
    kontrast
    konversation
    korganizer
    krdc
    krfb
    kruler
    ktimer
    ktorrent
    sweeper
    yakuake
  ];

  # Remote desktop
  # ==========================
  # krdp (Plasma 6.3 RDP server) is not packaged in nixpkgs; krfb is excluded
  # above. Use GNOME remote desktop (see ./gnome) or rustdesk instead.

  # IME: fcitx5 under KWin (Wayland input method frontend)
  # ==========================
  # KWin launches fcitx5 itself via zwp_input_method_v2 ("Virtual keyboard ->
  # Fcitx 5" setting). The desktop file comes from the fcitx5-with-addons
  # package so addons (rime, ...) load. KConfig merges /etc/xdg with the
  # user kwinrc, so both settings live system-wide and survive plasma-manager
  # resetting the user kwinrc.
  environment.etc."xdg/kwinrc".text = lib.mkIf (config.i18n.inputMethod.package != null) ''
    [Wayland]
    InputMethod=${config.i18n.inputMethod.package}/share/applications/org.fcitx.Fcitx5.desktop
  '';

  # Hide the package's XDG autostart entry via /etc/xdg (it precedes profile
  # paths in XDG_CONFIG_DIRS), so no autostart instance steals the
  # single-instance lock from the KWin-launched one.
  environment.etc."xdg/autostart/org.fcitx.Fcitx5.desktop".text = ''
    [Desktop Entry]
    Hidden=true
  '';

  # Declarative Plasma configuration (plasma-manager)
  # ==========================
  home-manager.users.${config.home.userName} = {
    imports = [
      inputs.plasma-manager.homeModules.plasma-manager
    ];

    programs.plasma = {
      enable = true;
      # Reset everything not set here to Plasma defaults on login.
      overrideConfig = true;

      kwin = {
        effects = {
          blur.enable = true;
          dimInactive.enable = true;
          windowOpenClose.animation = "glide";
          desktopSwitching.animation = "fade";
        };
        borderlessMaximizedWindows = true;
        nightLight.enable = true;
        virtualDesktops.number = 4;
      };

      # Floating, adaptive-transparency panel (blur kicks in over windows).
      panels = [
        {
          location = "bottom";
          height = 44;
          alignment = "center";
          floating = true;
          opacity = "adaptive";
          widgets = [
            "org.kde.plasma.kickoff"
            "org.kde.plasma.icontasks"
            "org.kde.plasma.marginsseparator"
            "org.kde.plasma.systemtray"
            "org.kde.plasma.digitalclock"
            "org.kde.plasma.showdesktop"
          ];
        }
      ];

      kscreenlocker = {
        autoLock = false;
        lockOnResume = false;
      };
    };
  };
}
