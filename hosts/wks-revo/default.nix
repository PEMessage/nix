{ inputs, config, ... }:
{
  # Host-specific NixOS module: remote access + host-pinned network tweaks.
  # Defined here (not in _nixos/configuration.nix) so that file only holds
  # rarely-changing machine facts (boot loader, hostname, locale, stateVersion).
  # The host imports it below, i.e. it enables itself.
  flake.modules.nixos."host.wks-revo" = {
    imports = [
      config.flake.modules.nixos.tailscale-force-derp
    ];

    # Force Tailscale over DERP + FakeHTTP + BBR (see the tailscale-force-derp
    # aspect).
    services.tailscaleForceDerp = {
      enable = true;
      interface = "enp3s0";
    };

    services.openssh.enable = true;

    programs.mosh = {
      enable = true;
      openFirewall = true;
    };

    # Pull in this host's home-manager module (per-user app config).
    home-manager.sharedModules = [ config.flake.modules.homeManager."host.wks-revo" ];
  };

  # Host-specific home-manager module: per-user app config for this host.
  flake.modules.homeManager."host.wks-revo" = {
    imports = [ config.flake.modules.homeManager.waynergy ];

    # Waynergy Synergy client (aspect app/waynergy).
    waynergy = {
      enable = true;
      host = "192.168.123.74";
    };
  };

  flake.nixosConfigurations.wks-revo = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./_nixos/configuration.nix
      config.flake.modules.nixos."host.wks-revo"
      config.flake.modules.nixos."user.pem"
      config.flake.modules.nixos.desktop
      config.flake.modules.nixos.desktop-extra

    ];
  };
}
