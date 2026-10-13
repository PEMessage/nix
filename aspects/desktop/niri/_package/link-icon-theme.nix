# link-icon-theme - a meta icon theme that ships no icons, only a chain:
#   LinkIcons -> Papirus-Dark -> breeze-dark -> Adwaita -> hicolor
# Always the dark chain: Papirus-Dark encodes currentColor as #dfdfdf (light),
# so action/symbolic icons stay readable on the dark bar.
#
# The real themes are propagated so buildEnv links them into
# /run/current-system/sw/share/icons with only this package listed.
{ lib, stdenvNoCC, writeText
, adwaita-icon-theme
, hicolor-icon-theme
, papirus-icon-theme
}:

let
  # most-preferred first; breeze-dark ships inside papirus-icon-theme.
  parents = [
    "Papirus-Dark"
    "breeze-dark"
    "Adwaita"
    "hicolor"
  ];
  indexTheme = writeText "LinkIcons-index.theme" ''
    [Icon Theme]
    Name=LinkIcons
    Comment=${lib.concatStringsSep ", " parents}
    Inherits=${lib.concatStringsSep "," parents}
  '';
in
stdenvNoCC.mkDerivation {
  pname = "link-icon-theme";
  version = "1";

  dontUnpack = true;

  propagatedUserEnvPkgs = [
    adwaita-icon-theme
    hicolor-icon-theme
    papirus-icon-theme
  ];

  installPhase = ''
    runHook preInstall
    install -Dm644 ${indexTheme} $out/share/icons/LinkIcons/index.theme
    runHook postInstall
  '';

  meta = with lib; {
    description = "Meta icon theme: LinkIcons -> Papirus-Dark -> breeze-dark -> Adwaita -> hicolor";
    platforms = platforms.all;
  };
}
