{
  lib,
  stdenvNoCC,
  fetchurl,
  _7zz,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "mochi";
  version = "1.18.11";

  src = fetchurl {
    url = "https://download.mochi.cards/releases/Mochi-${finalAttrs.version}-arm64.dmg";
    hash = "sha256-IzJx8IMuX/zK3GRIkwnqW7OCcmPLUSld3pVD6sCLAxA=";
  };

  # Use 7zz to work around APFS: https://discourse.nixos.org/t/help-with-error-only-hfs-file-systems-are-supported-on-ventura/25873/9
  nativeBuildInputs = [_7zz];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"
    cp -r *.app "$out/Applications"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Study notes and flashcards using spaced repetition";
    homepage = "https://mochi.cards/";
    license = lib.licenses.unfree;
    platforms = platforms.darwin;
    sourceProvenance = with sourceTypes; [binaryNativeCode];
  };
})
