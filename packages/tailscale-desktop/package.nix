{
  lib,
  stdenvNoCC,
  fetchurl,
  xar,
  cpio,
  pbzx,
  makeWrapper,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "tailscale-desktop";
  version = "1.84.1";

  src = fetchurl {
    url = "https://pkgs.tailscale.com/stable/Tailscale-${finalAttrs.version}-macos.pkg";
    hash = "sha256-xeCZRoDKZd15cUis/FWTGtO2g/mvkuSrdYYMs3r5z8M=";
  };

  nativeBuildInputs = [xar cpio pbzx makeWrapper];

  unpackPhase = ''
    runHook preUnpack

    xar -xf $src
    cd Distribution.pkg

    runHook postUnpack
  '';

  buildPhase = ''
    runHook preBuild

    pbzx -n Payload | cpio -i

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications/Tailscale.app
    cp -r Contents $out/Applications/Tailscale.app
    # mv $out/Applications/Tailscale.app/Contents/MacOS/Tailscale{,-unwrapped}
    # makeWrapper $out/Applications/Tailscale.app/Contents/MacOS/Tailscale{-unwrapped,} --add-flags "rungui"
    makeWrapper $out/Applications/Tailscale.app/Contents/MacOS/Tailscale $out/bin/tailscale

    runHook postInstall
  '';

  meta = with lib; {
    description = "Mesh VPN based on WireGuard";
    homepage = "https://tailscale.com/";
    platforms = platforms.darwin;
    sourceProvenance = with sourceTypes; [binaryNativeCode];
  };
})
