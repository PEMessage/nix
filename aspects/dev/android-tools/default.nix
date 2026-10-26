# android-tools - adb/fastboot, built from source.
#
# adb only attaches to a device whose USB interface carries the standard adb
# triple (class 0xff / subclass 0x42 / protocol 0x01); everything else is
# skipped *silently*, so a device can be visible in `lsusb` yet never appear in
# `adb devices`. Some vendor builds keep the adb wire protocol but renumber the
# function to ff/ff/ff.
#
# `vendorUsb` swaps in a build whose interface filter also accepts that triple,
# and adds the udev rule that lets adb open the device node (the distro rule
# sets only know the standard vendors).
#
# Enable per host, e.g. in the host module:
#   programs.android-tools.vendorUsb = true;
{ ... }:
{
  flake.aspects.android-tools.nixos =
    { config, lib, pkgs, ... }:
    let
      cfg = config.programs.android-tools;
    in
    {
      options.programs.android-tools.vendorUsb = lib.mkEnableOption ''
        adb support for devices that advertise the adb function as ff/ff/ff
        instead of ff/42/01 (patched build + udev rule)
      '';

      config = {
        environment.systemPackages = [
          (if cfg.vendorUsb then
            pkgs.callPackage ./_package/android-tools-vendor-usb.nix { }
          else
            pkgs.android-tools)
        ];

        # MODE=0666 instead of TAG+="uaccess": logind only hands out uaccess
        # ACLs to the active session on a seat, and WSL sessions have no seat,
        # so the ACL would never be applied there.
        services.udev.extraRules = lib.mkIf cfg.vendorUsb ''
          SUBSYSTEM=="usb", ATTR{idVendor}=="26f1", MODE="0666"
        '';
      };
    };
}
