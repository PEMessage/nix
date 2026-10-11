{ inputs, config, ... }:
{
  # Host-specific NixOS module: remote access + host-pinned network tweaks.
  # Defined here (not in _nixos/configuration.nix) so that file only holds
  # rarely-changing machine facts (boot loader, hostname, locale, stateVersion).
  # The host imports it below, i.e. it enables itself.
  flake.modules.nixos."host.wks-revo" = {
    # Enable the OpenSSH daemon.
    services.openssh.enable = true;

    programs.mosh = {
      enable = true;
      openFirewall = true;
    };

    # Force Tailscale over DERP + FakeHTTP + BBR (see the tailscale-force-derp
    # aspect).
    services.tailscaleForceDerp = {
      enable = true;
      interface = "enp3s0";
    };
  };

  flake.nixosConfigurations.wks-revo = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./_nixos/configuration.nix
      config.flake.modules.nixos."host.wks-revo"
      config.flake.modules.nixos.desktop-extra
      config.flake.modules.nixos.desktop
      config.flake.modules.nixos.tailscale-force-derp
      config.flake.modules.nixos."user.pem"
    ];
  };
}
