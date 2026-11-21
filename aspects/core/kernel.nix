# Security-critical updates from the separately pinned `nixpkgs-small` input
# (flake.nix). Only the kernel is taken from it; the rest keeps using `pkgs`.
#
# Not in `core`: WSL boots the Windows kernel and must not pull this in.
{ inputs, ... }:
{
  flake.aspects.kernel = {
    nixos =
      { pkgs, lib, config, ... }:
      let
        kernelPkgs = import inputs.nixpkgs-small {
          system = pkgs.stdenv.hostPlatform.system;
        };
        kernelPackages = kernelPkgs.linuxPackages_6_18;
        kernel = kernelPackages.kernel;

        # Build one in-tree module from a patched source tree, the same way
        # nixpkgs builds out-of-tree modules (`kernelModuleMakeFlags`). The
        # kernel package itself stays the unpatched one, so it is still
        # substitutable and, more importantly, its other ~5k modules are not
        # rebuilt.
        #
        # This only works for patches that touch code built as a module
        # (`=m`): the kernel image has to stay bit-identical to the unpatched
        # package. A patch to built-in code must go through
        # `boot.kernelPatches` instead, which rebuilds the world.
        rebuildInTreeModule =
          { module, patches }:
          kernelPackages.stdenv.mkDerivation {
            pname = "linux-module-${builtins.baseNameOf module}";
            inherit (kernel) version src;
            inherit patches;
            nativeBuildInputs = kernel.moduleBuildDependencies;
            enableParallelBuilding = true;
            hardeningDisable = [ "pic" ];
            makeFlags = kernelPackages.kernelModuleMakeFlags ++ [
              "M=$(PWD)/${module}"
              "INSTALL_MOD_PATH=${placeholder "out"}"
              "INSTALL_MOD_DIR=kernel/${module}"
              "INSTALL_MOD_STRIP=1"
            ];
            buildFlags = [ "modules" ];
            installFlags = [ "modules_install" ];
          };
      in
      {
        options.boot.kernelModulePatches = lib.mkOption {
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                module = lib.mkOption {
                  type = lib.types.str;
                  example = "drivers/gpu/drm/amd/amdgpu";
                  description = ''
                    In-tree module directory (the one holding the Makefile),
                    relative to the kernel source root.
                  '';
                };
                patches = lib.mkOption {
                  type = lib.types.listOf lib.types.path;
                  default = [ ];
                  description = "Patches to apply to that module's sources.";
                };
              };
            }
          );
          default = [ ];
          description = ''
            Rebuild individual in-tree modules from patched sources and
            inject them via {option}`boot.extraModulePackages`, leaving the
            kernel package (and every other module) untouched.

            Only valid for patches to code built as a module (`=m`); the
            kernel image and its ABI must not change.
          '';
        };

        config = {
          # Pin the LTS line; bare `linuxPackages` follows the branch default.
          boot.kernelPackages = kernelPackages;

          # The merged module tree is a `buildEnv`; on a path collision the
          # package with the higher priority (lower number) wins, so `hiPrio`
          # replaces the kernel's copy instead of erroring out.
          boot.extraModulePackages = map (m: lib.hiPrio (rebuildInTreeModule m)) config.boot.kernelModulePatches;
        };
      };
  };
}
