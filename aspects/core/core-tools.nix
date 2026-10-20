{ config, ... }:
{
  flake.aspects.core-tools = {
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
          iperf3

          # build
          gcc
          gnumake
          binutils
          autoconf
          automake

          # toolchain
          uv

          # system
          kbd
          openssl
          lsof

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

        # mesh VPN
        services.tailscale.enable = true;

        home-manager.sharedModules = [ config.flake.modules.homeManager.core-tools ];
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          (pkgs.writeShellScriptBin "pe-chezmoi-init" (builtins.readFile ./script/pe-chezmoi-init))
        ];
      };
  };
}
