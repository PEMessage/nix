{ ... }:
{
  # Browser-based device configurators (M HUB for MCHOSE mice, VIA/QMK for
  # keyboards, headset EQ pages, ...) speak WebHID, which opens /dev/hidraw*
  # directly. systemd's udev rules never tag hidraw with uaccess, so NixOS
  # ships those nodes as root:root 0600: a page can still list the device the
  # user already granted, but every open() fails with "Failed to open the
  # device" and the settings are silently dropped. 60-steam-vr.rules does
  # exactly this for VR headsets.
  #
  # MODE="0660" is load-bearing, not cosmetic: logind adds the uaccess ACL as a
  # named user entry whose mask is the group permission bits, so a 0600 node
  # would mask the ACL back to no access. Seat-scoped, so only the local
  # logged-in user gets it, which is on par with the /dev/input/event* access
  # the compositor already has.
  flake.aspects.hidraw.nixos = { ... }: {
    services.udev.extraRules = ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", TAG+="uaccess"
    '';
  };
}
