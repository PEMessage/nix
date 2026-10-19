# Machine facts for vm-citrine — the Alibaba Cloud ECS instance formerly known
# as vps-ali. Only rarely-changing things live here: boot loader, hostname,
# locale, stateVersion. Volatile config (remote access, network, secrets) lives
# in the host module in ../default.nix.
{ ... }:
{
  imports = [ ./hardware-configuration.nix ];

  # --- Boot ---------------------------------------------------------------
  # UEFI + hybrid GPT (see ./disk-config.nix): EF02 for a legacy GRUB fallback
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

  networking.hostName = "vm-citrine";

  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = "26.05";
}
