# The original qiniu cloud VM (KubeVirt), installed remotely with
# nixos-anywhere. Provider-specific bits only; the shared server config lives
# in ../common/configuration.nix.
{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ../common/configuration.nix
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "vps";

  # --- Boot ---------------------------------------------------------------
  # BIOS + GPT (see disk-config.nix). systemd-boot needs EFI, so GRUB it is.
  #
  # Do NOT set `boot.loader.grub.device(s)` here: because disk-config.nix has an
  # EF02 (BIOS boot) partition, disko already injects
  # `boot.loader.grub.devices = [ "/dev/vda" ]`. Setting it again makes
  # `mirroredBoots` contain the device twice and trips the assertion
  # "You cannot have duplicated devices in mirroredBoots".
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = false;

  # --- Self-hosted DERP relay ---------------------------------------------
  # The public IP is deliberately NOT in git: hostFile is pushed in at deploy
  # time (see --extra-files ./secrets/<alias>) and read via systemd
  # LoadCredential. The provider's NAT maps public :10228 -> this VM's :10164
  # for BOTH DERP/TCP and STUN/UDP, so `stun` just inherits `derp`.
  services.ipDerper = {
    enable = true;
    hostFile = "/var/lib/nixos-secrets/derper-host";
    derp.publicPort = 10228;
    derp.listenPort = 10164;
  };
}
