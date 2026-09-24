# Disk layout for the vps cloud VM, applied by nixos-anywhere + disko.
#
# The VM boots in BIOS mode (no /sys/firmware/efi), so we use a GPT with a
# 1 MiB "BIOS boot" partition (type EF02) that GRUB embeds its core.img into.
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
            type = "EF02"; # bios_grub, required by GRUB on GPT
          };
          boot = {
            name = "boot";
            size = "1G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/boot";
              mountOptions = [ "defaults" ];
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
