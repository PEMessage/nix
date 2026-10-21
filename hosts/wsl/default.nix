{ inputs, config, ... }:
{
  flake.modules.nixos."host.wsl" = { config, pkgs, ... }: {
    networking.hostName = "wsl";
    time.timeZone = "Asia/Shanghai";

    wsl.useWindowsDriver = true;

    # Foreign binaries (the host's nvidia-smi, vendor CUDA wheels, ...) go
    # through nix-ld, and NIX_LD_LIBRARY_PATH is the only library path they
    # consult. Expose the Windows driver libs there instead of polluting the
    # global LD_LIBRARY_PATH: Nix-built programs already find them in
    # /run/opengl-driver via hardware.graphics.extraPackages above.
    programs.nix-ld.libraries = [ config.wsl.wslLib ];

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
