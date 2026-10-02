# Alibaba Cloud ECS instance (this host), installed remotely with
# nixos-anywhere. Provider-specific bits only; the shared server config lives
# in ../common/configuration.nix.
{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ../common/configuration.nix
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "vps-ali";

  # --- Boot ---------------------------------------------------------------
  # UEFI + hybrid GPT (see disk-config.nix): EF02 for a legacy GRUB fallback
  # and EF00 (the ESP) mounted at /boot for the real UEFI boot.
  #
  # efiInstallAsRemovable drops EFI/BOOT/BOOTX64.EFI in the firmware's
  # hardcoded fallback path, which the grub module only allows when
  # canTouchEfiVariables is false. That is also what we want here: the EFI
  # variables are not reliably writable from the nixos-anywhere kexec
  # installer, so we must not depend on writing an NVRAM boot entry.
  #
  # Do NOT set boot.loader.grub.devices: disko injects it from the EF02
  # partition (setting it again trips "duplicated devices in mirroredBoots").
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  # --- Honeypot -----------------------------------------------------------
  # Open the decoy ports (HTTP/SSH/FTP, see os/server.nix) on the public NIC.
  # NixOS uses systemd's predictable names, so the ECS virtio NIC is ens5 here
  # (the vendor Ubuntu called it eth0 because of `net.ifnames=0`).
  vps.publicInterface = "ens5";

  # --- Self-hosted DERP relay ---------------------------------------------
  # Unlike qiniu, the ECS public IP is a 1:1 NAT, so derper binds the public
  # port directly (listen == public) for both DERP/TCP and STUN/UDP. The port
  # must be allowed in the security group.
  services.ipDerper = {
    enable = true;
    hostFile = "/var/lib/nixos-secrets/derper-host";
    derp.publicPort = 10228;
  };
}
