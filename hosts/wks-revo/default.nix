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


    # DDC/CI access without sudo. hardware.i2c.enable loads i2c-dev and
    # installs a udev rule with `uaccess` (the locally logged-in seat user
    # gets an ACL) and GROUP=i2c/MODE=0660. The group membership is for SSH
    # sessions, which are not tied to a local seat and therefore do not get
    # the uaccess ACL. i2c-tools provides i2ctransfer for raw DDC/CI tests.
    hardware.i2c.enable = true;
    # users.users.pem.extraGroups = [ "i2c" ];
    environment.systemPackages = [
      pkgs.i2c-tools
      pkgs.ddcutil
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
