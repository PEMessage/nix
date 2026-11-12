# android-tools with two adb behaviour patches (see each patch's comment for
# the full rationale):
#
# - vendor-usb: adb decides what to attach to from the USB interface triple
#   alone, in is_adb_interface(); anything that is not ff/42/01 is skipped
#   silently. Some vendor builds keep the adb wire protocol but renumber the
#   function to ff/ff/ff, so stock adb (and the prebuilt Google platform-tools)
#   never see the device even though `lsusb` does. The patch widens that one
#   predicate only.
# - server-version: a running adb server that reports version 31 is accepted
#   instead of being killed over the version mismatch.
{ android-tools }:

android-tools.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [
    ./android-tools-vendor-usb.patch
    ./android-tools-server-version.patch
  ];
})
