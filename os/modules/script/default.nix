{ lib, pkgs, config, ... }:

let
  # Build one script derivation. `pkgs'` lets the same helper serve both the
  # NixOS (system) and home-manager (user) package sets.
  mkScript = pkgs': name: src:
    if lib.isString src
    then pkgs'.writeShellScriptBin name src
    else
      pkgs'.runCommandLocal name { } ''
        mkdir -p $out/bin
        install -Dm755 ${src} "$out/bin/${name}"
      '';

  scriptOption = lib.mkOption {
    type = with lib.types; attrsOf (either path str);
    default = { };
    description = "Convenience scripts placed on PATH. Maps a script name to a file path or an inline string.";
    example = ./scripts/init-chezmoi;
  };

  # home-manager module: per-user script, injected into every home user below.
  homeModule = { lib, pkgs, config, ... }: {
    options.script = scriptOption;
    config.home.packages = lib.mapAttrsToList (mkScript pkgs) config.script;
  };
in
{
  options.script = scriptOption;

  config = {
    environment.systemPackages = lib.mapAttrsToList (mkScript pkgs) config.script;

    home-manager.sharedModules = [ homeModule ];
  };
}
