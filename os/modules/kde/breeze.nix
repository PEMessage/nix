# breeze: default Breeze look (blur strength, panel/dock layout).
{ lib, pkgs, ... }:
{
  home-manager.sharedModules = [
    (
      { ... }:
      {
        programs.plasma = {
          # Dark theme (global theme, plasma style and color scheme).
          workspace = {
      lookAndFeel = "org.kde.breezedark.desktop";
      theme = "breeze-dark";
      colorScheme = "BreezeDark";
    };

    # Maximum frosted-glass blur on translucent surfaces.
    kwin = {
      effects.blur = {
        enable = true;
        strength = 15; # 1-15, default 5
        noiseStrength = 0; # 0-14, default 8; 0 = smooth gaussian, no grain
      };
    };

    panels = [
      # Top bar: centered clock, tray right-aligned; dodges windows.
      {
        location = "top";
        alignment = "center";
        floating = true;
        opacity = "translucent"; # always semi-transparent frosted glass
        hiding = "dodgewindows";
        widgets = [
          "org.kde.plasma.panelspacer"
          "org.kde.plasma.digitalclock"
          "org.kde.plasma.panelspacer"
          "org.kde.plasma.marginsseparator"
          "org.kde.plasma.systemtray"
        ];
      }
      # Bottom dock: launcher + task manager only; fits content width;
      # dodges windows.
      {
        location = "bottom";
        alignment = "center";
        lengthMode = "fit";
        floating = true;
        opacity = "translucent"; # always semi-transparent frosted glass
        hiding = "dodgewindows";
        widgets = [
          "org.kde.plasma.kickoff"
          "org.kde.plasma.icontasks"
        ];
      }
    ];
  }
      )
    ];
}
