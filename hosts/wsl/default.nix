{ inputs, config, ... }:
{
  flake.modules.nixos."host.wsl" = {
    networking.hostName = "wsl";
    time.timeZone = "Asia/Shanghai";
  };

  flake.nixosConfigurations.wsl = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./_nixos/configuration.nix
      config.flake.modules.nixos."host.wsl"
      config.flake.modules.nixos.desktop
      config.flake.modules.nixos."user.nixos"
    ];
  };
}
