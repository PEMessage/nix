# link-icon-theme - a meta icon theme: a chain plus a light symbolic overlay:
#   LinkIcons -> Papirus-Dark -> breeze-dark -> Adwaita -> hicolor
# Always the dark chain: Papirus-Dark encodes currentColor as #dfdfdf (light),
# so Papirus' action/symbolic icons stay readable on the dark bar.
#
# Gap: neither Papirus-Dark nor breeze-dark ship any *-symbolic.svg, so every
# symbolic lookup falls through to Adwaita, whose symbolic icons hardcode the
# light-theme foreground (#2e3436, #474747, ...). GTK recolors symbolic icons,
# but Qt/Quickshell (DMS) does not, so they render near-invisible on the dark
# bar. LinkIcons therefore ships a recolored copy of Adwaita's symbolic set
# (greys flattened to `foreground`, semantic accents kept) which wins the
# lookup before the original Adwaita ones are ever reached.
#
# The real themes are propagated so buildEnv links them into
# /run/current-system/sw/share/icons with only this package listed.
{ lib, stdenvNoCC
, adwaita-icon-theme
, hicolor-icon-theme
, papirus-icon-theme
}:

let
  # Adwaita's symbolic foreground colours, all flattened to this light grey
  # (matches Papirus-Dark's currentColor). Semantic accent colours are kept.
  foreground = "#dfdfdf";

  # most-preferred first; breeze-dark ships inside papirus-icon-theme.
  parents = [
    "Papirus-Dark"
    "breeze-dark"
    "Adwaita"
    "hicolor"
  ];
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
    icondir=$out/share/icons/LinkIcons
    mkdir -p "$icondir"

    # light overlay: a recolored copy of Adwaita's symbolic set, looked up
    # before the dark originals in the Adwaita fallback.
    cp -r ${adwaita-icon-theme}/share/icons/Adwaita/symbolic "$icondir/symbolic"
    chmod -R u+w "$icondir/symbolic"

    # flatten Adwaita's hardcoded foreground greys to ${foreground} (the -E
    # alternation and the trailing \b keep the short #222 from eating #222222)
    find "$icondir/symbolic" -name '*.svg' -print0 |
      xargs -0 sed -i -E \
        -e 's/#2e3436/${foreground}/gI' \
        -e 's/#2e3434/${foreground}/gI' \
        -e 's/#2d3336/${foreground}/gI' \
        -e 's/#474747/${foreground}/gI' \
        -e 's/#222222/${foreground}/gI' \
        -e 's/#222\b/${foreground}/gI'

    # a few icons carry no fill at all and would render black; give the root
    # <svg> the foreground as an inherited default.
    while IFS= read -r f; do
      sed -i "s/<svg/<svg fill=\"${foreground}\"/" "$f"
    done < <(grep -rL 'fill' "$icondir/symbolic" --include='*.svg' || true)

    {
      echo '[Icon Theme]'
      echo 'Name=LinkIcons'
      echo 'Comment=${lib.concatStringsSep ", " parents}'
      echo 'Inherits=${lib.concatStringsSep "," parents}'
      echo
      # one [symbolic/<ctx>] stanza per context we ship, so the overlay's icons
      # are actually listed (a theme with no Directories has no icons).
      for d in "$icondir"/symbolic/*; do
        ctx=''${d##*/}
        case "$ctx" in
          actions) context=Actions ;;
          apps) context=Applications ;;
          categories) context=Categories ;;
          devices) context=Devices ;;
          emblems) context=Emblems ;;
          emotes) context=Emotes ;;
          mimetypes) context=MimeTypes ;;
          places) context=Places ;;
          status) context=Status ;;
          legacy) context=Legacy ;;
          ui) context=UI ;;
          *) context=Other ;;
        esac
        printf '[symbolic/%s]\nContext=%s\nSize=16\nMinSize=8\nMaxSize=512\nType=Scalable\n\n' "$ctx" "$context"
      done
    } > "$icondir/index.theme"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Meta icon theme: LinkIcons -> Papirus-Dark -> breeze-dark -> Adwaita -> hicolor, with a light Adwaita-symbolic overlay";
    platforms = platforms.all;
  };
}
