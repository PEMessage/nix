{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # c/c++
    gdb

    # rust
    rustc
    cargo

    # bun
    bun

    # uv
    uv
  ];
}
