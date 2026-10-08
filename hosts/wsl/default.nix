{ inputs, config, ... }:
{
  flake.nixosConfigurations.wsl = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./_nixos/configuration.nix
      config.flake.modules.nixos.home-manager
      config.flake.modules.nixos."user.nixos"
    ];
  };
}
