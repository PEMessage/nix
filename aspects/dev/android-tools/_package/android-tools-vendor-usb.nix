# android-tools with adb's USB interface filter widened to also accept the
# vendor-remapped ff/ff/ff function (see the patch's comment).
#
# adb decides what to attach to from the USB interface triple alone, in
# is_adb_interface(); anything that is not ff/42/01 is skipped silently. Some
# vendor builds keep the adb wire protocol but renumber the function, so stock
# adb (and the prebuilt Google platform-tools) never see the device even
# though `lsusb` does. The patch widens that one predicate only.
{ android-tools }:

android-tools.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [ ./android-tools-vendor-usb.patch ];
})
