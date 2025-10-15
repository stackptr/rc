{
  lib,
  fetchFromGitHub,
  buildGoModule,
  buildNpmPackage,
  nix-update-script,
}: let
  version = "0.8.8-beta";

  src = fetchFromGitHub {
    owner = "gtsteffaniak";
    repo = "filebrowser";
    rev = "v${version}";
    hash = "";
  };

  frontend = buildNpmPackage rec {
    pname = "filebrowser-quantum-frontend";
    inherit version src;

    sourceRoot = "${src.name}/frontend";

    npmDepsHash = "";

    npmBuildScript = "build";

    installPhase = ''
      runHook preInstall

      mkdir $out
      mv dist $out

      runHook postInstall
    '';
  };
in
  buildGoModule {
    pname = "filebrowser-quantum";
    inherit version src;

    vendorHash = "";

    excludedPackages = ["tools"];

    preBuild = ''
      cp -r ${frontend}/dist frontend/
    '';

    ldflags = [
      "-X github.com/filebrowser/filebrowser/v2/version.Version=v${version}"
    ];

    passthru = {
      updateScript = nix-update-script {};
      inherit frontend;
    };

    meta = with lib; {
      description = "Fork of filebrowser project";
      homepage = "https://github.com/gtsteffaniak/filebrowser";
      license = licenses.asl20;
      mainProgram = "filebrowser";
    };
  }
