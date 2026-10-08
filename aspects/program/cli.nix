{ ... }:
{
  flake.aspects.cli = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          # utils
          git
          vim
          which
          python3
          wget
          bc
          file
          kmod

          # network
          dig
          nixos-firewall-tool

          # build
          gcc
          gnumake
          binutils
          autoconf
          automake

          # system
          kbd
          openssl

          # zip
          _7zz
          unzip

          # modern unix
          neovim
          fzf
          ripgrep
          tealdeer

          # latest
          unstable.tmux
        ];
      };
  };
}
