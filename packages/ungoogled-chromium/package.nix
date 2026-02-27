{
  lib,
  stdenvNoCC,
  fetchurl,
  undmg,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "ungoogled-chromium";
  version = "136.0.7103.113-1.1";

  src = fetchurl {
    url = "https://github.com/ungoogled-software/ungoogled-chromium-macos/releases/download/${finalAttrs.version}/ungoogled-chromium_${finalAttrs.version}_arm64-macos.dmg";
    hash = "sha256-llaXl2jEegL0DyUBHDW15d8jNXr+kF+TJkrBONIlXCU=";
  };

  nativeBuildInputs = [undmg];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"
    cp -r *.app "$out/Applications"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Open source web browser from Google with dependencies on Google web services removed";
    homepage = "https://github.com/ungoogled-software/ungoogled-chromium-macos";
    license = lib.licenses.bsd3;
    mainProgram = "chromium";
    platforms = platforms.darwin;
    sourceProvenance = with sourceTypes; [binaryNativeCode];
  };
})
