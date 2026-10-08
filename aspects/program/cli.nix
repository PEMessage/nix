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

          # dotfiles
          chezmoi

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

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          (pkgs.writeShellScriptBin "pe-chezmoi-init" (builtins.readFile ./pe-chezmoi-init))
        ];
      };
  };
}
