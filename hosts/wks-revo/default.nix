{ inputs, config, ... }:
{
  # Host-specific NixOS module: remote access + host-pinned network tweaks.
  # Defined here (not in _nixos/configuration.nix) so that file only holds
  # rarely-changing machine facts (boot loader, hostname, locale, stateVersion).
  # The host imports it below, i.e. it enables itself.
  flake.modules.nixos."host.wks-revo" = { ... }: {
    imports = [
      config.flake.modules.nixos.tailscale-force-derp
      config.flake.modules.nixos.kernel
    ];

    # Host-level DRM guards for the AMD DP AUX I2C error path. A partial AUX
    # write can report a status byte larger than the requested transfer size;
    # dm_dp_aux_transfer() trusts it as a byte count, drm_dp_i2c_drain_msg()
    # subtracts it from size_t msg.size, and the resulting huge value makes
    # drm_dp_i2c_do_msg() divide by zero. These are not monitor-toggle-only,
    # so they live with the host rather than in the monitor-toggle aspect.
    boot.kernelPatches = [
      {
        name = "drm-dp-guard-i2c-drain-underflow";
        patch = ./patches/0001-drm-dp-guard-i2c-drain-underflow.patch;
      }
      {
        name = "drm-amdgpu-validate-partial-aux-write";
        patch = ./patches/0002-drm-amdgpu-validate-partial-aux-write.patch;
      }
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

    # Bluetooth (this is the only host with radio hardware).
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    # DMS battery widget and control-center power profile.
    services.upower.enable = true;
    services.power-profiles-daemon.enable = true;

    # Pull in this host's home-manager module (per-user app config).
    home-manager.sharedModules = [ config.flake.modules.homeManager."host.wks-revo" ];
  };

  # Host-specific home-manager module: per-user app config for this host.
  flake.modules.homeManager."host.wks-revo" = { ... }: {
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
