{ inputs, config, ... }:
{
  flake.modules.nixos."host.wsl" = { config, pkgs, ... }: {
    imports = [ inputs.wsl-binder.nixosModules.default ];

    networking.hostName = "wsl";
    time.timeZone = "Asia/Shanghai";

    # Out-of-tree binder for Microsoft's kernel; loads via modprobe's `install`
    # rule straight from the store, so /lib/modules is never touched.
    services.wsl-binder.enable = true;

    # The binder release assets double as a binary cache. Keep it scoped to
    # this host: in the top-level nixConfig every host queried GitHub for
    # unrelated store paths, which trips the release-asset abuse detector
    # (HTTP 429) and stalls builds for minutes.
    nix.settings = {
      extra-substituters = [ "https://github.com/PEMessage/wsl-binder/releases/latest/download" ];
      extra-trusted-public-keys = [ "wsl-binder-1:+J56oPBLvItpSBAJ3RBDy6G9vxzPEP8VwXqJ6aIo2sI=" ];
    };

    wsl.useWindowsDriver = true;

    # USB devices reach WSL through usbipd, and this module is also the only
    # thing that turns services.udev back on (WSL defaults it off, there is no
    # hardware to probe). Without it no udev rules are generated at all, so the
    # adb rule in the android-tools aspect would never run.
    wsl.usbip.enable = true;

    # The device attached here advertises its adb function as ff/ff/ff.
    programs.android-tools.vendorUsb = true;

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
