{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # rust
    rustc
    cargo

    # bun
    bun

    # uv
    uv
  ];
}
