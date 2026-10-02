# apollo - self-hosted game streaming host for Moonlight / Artemis.
#
# Wraps github:angelus788/apollo-flake (module + package) and adds two local
# fixes needed on this machine:
#
# 1. Clipboard sync on Linux. Upstream leaves platf::get_clipboard() and
#    platf::set_clipboard() as stubs on Linux (they only exist on Windows), so
#    Artemis' clipboard sync fails with "Setting clipboard failed!".
#    apollo-linux-clipboard.patch implements them via wl-clipboard. Apollo's
#    clipboard protocol is text-only, so images are not supported.
#
# 2. KMS screen capture instead of the default Wayland (wlr) backend. The wlr
#    backend never sets img->frame_timestamp, which makes video::encode_run()
#    dereference an empty std::optional and drop every frame after the first
#    keyframe (client shows only the first frame). KMS sets the timestamp.
#    See ~/docs/apollo-moonlight-first-frame-debug.md.
{
  lib,
  pkgs,
  inputs,
  ...
}: let
  apollo = inputs.apollo-flake.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./apollo-linux-clipboard.patch ];

    # The patched code shells out to wl-paste/wl-copy. The apollo module clears
    # the systemd unit's PATH, so put wl-clipboard on the binary's PATH here.
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
    postFixup = (old.postFixup or "") + ''
      wrapProgram "$out/bin/sunshine" \
        --prefix PATH : ${lib.makeBinPath [ pkgs.wl-clipboard ]}
    '';
  });
in {
  imports = [ inputs.apollo-flake.nixosModules.default ];

  services.apollo = {
    enable = true;
    package = apollo;

    # CAP_SYS_ADMIN is required for DRM/KMS screen capture. The module turns
    # this into a security.wrappers.apollo capability wrapper.
    capSysAdmin = true;

    openFirewall = true;

    # The default Wayland (wlr) capture backend is broken (see header comment),
    # so use KMS instead. Note: setting `settings` makes the module pass a
    # read-only config file from the Nix store, so changes made in the web UI
    # will not persist across restarts.
    settings.capture = "kms";
  };
}
