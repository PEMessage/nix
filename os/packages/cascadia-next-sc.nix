{ lib, stdenvNoCC, fetchurl }:

stdenvNoCC.mkDerivation {
  pname = "cascadia-next-sc";
  version = "cascadia-next";

  src = fetchurl {
    url = "https://github.com/microsoft/cascadia-code/releases/download/cascadia-next/CascadiaNextSC.wght.ttf";
    sha256 = "sha256-Dy1DJF+vjJ6kyU2qLL0HhT4xCONH6W/UTjfWrqqKfu8=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 $src $out/share/fonts/truetype/CascadiaNextSC.wght.ttf
    runHook postInstall
  '';

  meta = with lib; {
    description = "Cascadia Next SC (variable weight), the simplified Chinese variant of Cascadia Code";
    homepage = "https://github.com/microsoft/cascadia-code";
    license = licenses.ofl;
    platforms = platforms.all;
  };
}
