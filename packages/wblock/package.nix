# TODO: Build from source and upstream
{
  lib,
  stdenvNoCC,
  fetchurl,
  _7zz,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "wblock";
  version = "2.0.0";

  src = fetchurl {
    url = "https://github.com/0xCUB3/wBlock/releases/download/${finalAttrs.version}/wBlock.dmg";
    hash = "sha256-emcEURH/G6Laph4/P4vGJ+Ht6QvOjijrDh1qgstGMVo=";
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
    description = "Next-generation ad blocker for Safari";
    homepage = "https://github.com/0xCUB3/wBlock";
    license = lib.licenses.gpl3Only;
    platforms = platforms.darwin;
    sourceProvenance = with sourceTypes; [binaryNativeCode];
  };
})
