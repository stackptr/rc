{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "fastscripts";
  version = "2.8.3";

  src = fetchurl {
    url = "https://redsweater.s3.amazonaws.com/FastScripts${finalAttrs.version}.zip";
    hash = "sha256-DpQvaJ4pZWE8hwKr4hRJYITF6UFHvYfJlj+zkhYenTI=";
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
    description = "Tool for running time-saving scripts";
    homepage = "https://redsweater.com/fastscripts/";
    license = licenses.unfree;
    platforms = platforms.darwin;
    sourceProvenance = with sourceTypes; [binaryNativeCode];
  };
})
