# TODO: Upstream
{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "claude-desktop";
  version = "0.10.14";

  src = fetchurl {
    url = "https://storage.googleapis.com/osprey-downloads-c02f6a0d-347c-492b-a752-3e0651722e97/nest/release-${finalAttrs.version}-artifact-27cc6f763724a1af75b35c386a6b8d014eedc334.zip";
    hash = "sha256-7344lQfhDuxJN3bcaMefUxCgtTEIBV/lssMUrlU2kbw=";
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
    description = "Anthropic's official Claude AI desktop app";
    homepage = "https://claude.ai/download";
    license = licenses.unfree;
    platforms = platforms.darwin;
    sourceProvenance = with sourceTypes; [binaryNativeCode];
  };
})
