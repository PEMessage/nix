# Headless server hosts: core plus the server-only extras, no dev toolchain and
# no GUI. A host picks this instead of `core` / `desktop`.
#
# v1's os/server.nix also carried derper, docker and services/compose; enable
# those here as they get ported, rather than re-deriving the list per host.
{ config, ... }:
{
  flake.modules.nixos.server.imports = [
    config.flake.modules.nixos.core
    config.flake.modules.nixos.server-tools
  ];
}
