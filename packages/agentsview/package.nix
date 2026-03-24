{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
}: let
  version = "0.15.0";

  sources = {
    x86_64-linux = {
      url = "https://github.com/wesm/agentsview/releases/download/v${version}/agentsview_${version}_linux_amd64.tar.gz";
      hash = "sha256-Ycq5fkkUCxQ6SXXdUx5Sel7lOur8E0UieoBEca1R61g=";
    };
    aarch64-darwin = {
      url = "https://github.com/wesm/agentsview/releases/download/v${version}/agentsview_${version}_darwin_arm64.tar.gz";
      hash = "sha256-OCEqzRoozWklgajOHNwATSl+aCeog82xds3U+ElRw2g=";
    };
  };

  src = fetchzip (sources.${stdenv.hostPlatform.system} or (throw "unsupported system: ${stdenv.hostPlatform.system}"));
in
  stdenv.mkDerivation {
    pname = "agentsview";
    inherit version src;

    nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [autoPatchelfHook];

    installPhase = ''
      runHook preInstall
      install -Dm755 agentsview $out/bin/agentsview
      runHook postInstall
    '';

    meta = with lib; {
      description = "Local-first viewer for AI agent coding sessions";
      homepage = "https://github.com/wesm/agentsview";
      license = licenses.mit;
      mainProgram = "agentsview";
      platforms = builtins.attrNames sources;
    };
  }
