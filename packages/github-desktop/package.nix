# TODO: Build from source and upstream
{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "github-desktop";
  version = "3.4.19";

  src = fetchurl {
    url = "https://github.com/desktop/desktop/releases/download/release-${finalAttrs.version}/GitHub.Desktop-arm64.zip";
    hash = "sha256-ircv8/fWS8JX4fWWxGpFaOSw5uuPZ3JtYenBdU/vlls=";
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
    description = "GUI for managing Git and GitHub";
    homepage = "https://desktop.github.com/";
    license = licenses.mit;
    mainProgram = "github-desktop";
    platforms = platforms.darwin;
    sourceProvenance = with sourceTypes; [binaryNativeCode];
  };
})
