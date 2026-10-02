# Disk layout for the Alibaba Cloud ECS instance, applied by
# nixos-anywhere + disko.
#
# The instance boots in UEFI mode (the vendor image had a vfat ESP mounted at
# /boot/efi), so unlike ../other/disk-config.nix this is a *hybrid* GPT: a 1 MiB
# EF02 "BIOS boot" partition (so GRUB can still be embedded for a legacy boot)
# plus a real EF00 EFI system partition mounted at /boot. This mirrors disko's
# example/hybrid.nix.
{ lib, ... }:
{
  disko.devices = {
    disk.main = {
      device = lib.mkDefault "/dev/vda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          bios = {
            name = "bios";
            size = "1M";
            type = "EF02"; # bios_grub, for GRUB on GPT (legacy fallback)
          };
          boot = {
            name = "boot";
            size = "1G";
            type = "EF00"; # EFI system partition
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            name = "root";
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [ "defaults" ];
            };
          };
        };
      };
    };
  };
}
