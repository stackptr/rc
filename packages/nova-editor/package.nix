# TODO: Upstream
{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "nova-editor";
  version = "12.4";

  src = fetchurl {
    url = "https://download-cdn.panic.com/nova/Nova%20${finalAttrs.version}.zip";
    hash = "sha256-bDjr5bxq6F5bmYAxhjIdc64uHfaapAgfULq+o+RuSSs=";
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
    description = "Native code editor";
    homepage = "https://nova.app/";
    changelog = "https://nova.app/releases/${finalAttrs.version}/";
    license = licenses.unfree;
    platforms = platforms.darwin;
    sourceProvenance = with sourceTypes; [binaryNativeCode];
    mainProgram = "nova";
  };
})
