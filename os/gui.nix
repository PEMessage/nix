{ config, pkgs, ... }:
{
  # Thanks to: https://zhuanlan.zhihu.com/p/463403799
  fonts = {
    fonts= with pkgs; [
      adwaita-fonts # GNOME font
      noto-fonts-color-emoji
      nerd-fonts.symbols-only

      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      cascadia-code
    ];

    fontconfig = {
      defaultFonts = {
        emoji = [ "Noto Color Emoji" ];
        monospace = [
          "Noto Sans Mono CJK SC"
          "DejaVu Sans Mono"
        ];
        sansSerif = [
          "Noto Sans CJK SC"
          "DejaVu Sans"
        ];
        serif = [
          "Noto Serif CJK SC"
          "DejaVu Serif"
        ];
      };
    };
  };

}
