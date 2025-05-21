# TODO: Build from source and upstream
{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "scroll-reverser";
  version = "1.9";

  src = fetchurl {
    url = "https://pilotmoon.com/downloads/ScrollReverser-${finalAttrs.version}.zip";
    hash = "sha256-CWHbtvjvTl7dQyvw3W583UIZ2LrIs7qj9XavmkK79YU=";
  };

  dontUnpack = true;

  nativeBuildInputs = [unzip];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"
    unzip -d "$out/Applications" $src

    runHook postInstall
  '';

  meta = with lib; {
    description = "Tool to reverse the direction of scrolling";
    homepage = "https://pilotmoon.com/scrollreverser/";
    license = licenses.asl20;
    platforms = platforms.darwin;
    sourceProvenance = with sourceTypes; [binaryNativeCode];
  };
})
