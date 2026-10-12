# link-icon-theme - two "meta" icon themes that ship no icons of their own, only
# an Inherits chain, one per light/dark mode:
#
#   LinkDark  -> Papirus-Dark -> breeze-dark -> Adwaita -> hicolor
#   LinkLight -> Papirus      -> breeze      -> Adwaita -> hicolor
#
# Papirus(-Dark) comes first because it still provides the classic action icons
# (view-refresh, application-exit) that Adwaita dropped in GNOME 45+. breeze(-dark)
# is listed explicitly before Adwaita: Papirus already inherits it, but the chain
# is walked breadth-first, so without this it would land after hicolor and lose to
# Adwaita's symbolic icons. Adwaita is the fallback for names Papirus/breeze lack,
# and hicolor is the universal end of every chain.
#
# DMS picks the right one via iconThemePerMode (iconThemeDark/iconThemeLight).
#
# The three real themes are pulled in as `propagatedUserEnvPkgs`: buildEnv
# (what environment.systemPackages / home.packages use) follows
# nix-support/propagated-user-env-packages, so adding only this package is
# enough for all of them to land in /run/current-system/sw/share/icons.
{ lib, stdenvNoCC, writeText
, adwaita-icon-theme
, hicolor-icon-theme
, papirus-icon-theme
}:

let
  mkIndex = name: parents: writeText "${name}-index.theme" ''
    [Icon Theme]
    Name=${name}
    Comment=${lib.concatStringsSep ", " parents}
    Inherits=${lib.concatStringsSep "," parents}
  '';

  darkParents = [ "Papirus-Dark" "breeze-dark" "Adwaita" "hicolor" ];
  lightParents = [ "Papirus" "breeze" "Adwaita" "hicolor" ];
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
    install -Dm644 ${mkIndex "LinkDark" darkParents} $out/share/icons/LinkDark/index.theme
    install -Dm644 ${mkIndex "LinkLight" lightParents} $out/share/icons/LinkLight/index.theme
    runHook postInstall
  '';

  meta = with lib; {
    description = "Meta icon themes (LinkDark/LinkLight) chaining Papirus, breeze, Adwaita and hicolor";
    platforms = platforms.all;
  };
}
