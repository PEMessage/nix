{ inputs, config, ... }:
{
  flake.nixosConfigurations.wks-revo = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./_nixos/configuration.nix
      config.flake.modules.nixos.desktop-extra
      config.flake.modules.nixos.desktop
      config.flake.modules.nixos.tailscale-force-derp
      config.flake.modules.nixos."user.pem"
    ];
  };
}
