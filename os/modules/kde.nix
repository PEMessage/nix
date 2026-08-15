# kde: KDE Plasma 6 desktop (SDDM login + KWin Wayland session).
# Drop-in alternative to ./gnome: swap the import in os/x.nix to use it.
# Note: like the GNOME module, this is a desktop (x) host module and is not
# imported on WSL.
{ config, lib, pkgs, ... }:
{
  # SDDM with autologin
  # ==========================
  services.displayManager.sddm = {
    enable = true;
    autoNumlock = true;
    # Wayland (KWin) login screen instead of the X11 one.
    wayland.enable = true;
  };
  services.displayManager.autoLogin = {
    enable = true;
    user = config.home.userName;
  };
  services.desktopManager.plasma6.enable = true;

  # Trim
  # ==========================

  # Trim KDE defaults: drop the apps we don't use.
  # Kept: dolphin, kate, konsole, okular, spectacle, kcalc, kwrite,
  # gwenview, ark, plasma-systemmonitor, systemsettings, etc.
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

  # Remote Desktop
  # ==========================

  # Plasma 6.3 ships an RDP server (krdp), but it is not packaged in nixpkgs
  # yet; VNC via krfb is excluded above. Use GNOME remote desktop (see the
  # gnome module) or a third-party solution (e.g. rustdesk) instead.

  # IME
  # ==========================

  # fcitx5 (os/modules/ime.nix) is shared with GNOME. KWin implements
  # zwp_input_method_v2, so the Wayland frontend is used automatically once
  # the GNOME module (and its waylandFrontend workaround) is gone.

  # Lock screen
  # ==========================

  # Never auto-lock the screen (mirrors the GNOME screensaver setting).
  # Written to the user's config dir; KDE Settings can override this.
  home-manager.users.${config.home.userName}.home.file.".config/kscreenlockerrc" = {
    text = ''
      [Daemon]
      Autolock=false
      LockOnResume=false
    '';
  };
}
