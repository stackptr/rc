# TODO: Upstream to NixOS/nixpkgs
{
  lib,
  fetchFromGitHub,
  buildGoModule,
  buildNpmPackage,
  nix-update-script,
}: let
  version = "1.0.1-dev";

  src = fetchFromGitHub {
    owner = "stackptr";
    repo = "filebrowser";
    rev = "v${version}";
    hash = "sha256-BE+WQwRFHvGakGNPl84eVkkQMqKqF31CG0Y3E1nJkNk=";
  };

  frontend = buildNpmPackage rec {
    pname = "filebrowser-quantum-frontend";
    inherit version src;

    sourceRoot = "${src.name}/frontend";

    npmDepsHash = "sha256-Ro58WpzrreDb23sHiI9/ZekQBDl+VO271SImtEFgvYg=";

    npmBuildScript = "build:docker"; # Default build target requires writing outside frontend dir

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
      "-w"
      "-s"
      "-X 'github.com/gtsteffaniak/filebrowser/backend/version.CommitSHA=testingCommit'"
      "-X 'github.com/gtsteffaniak/filebrowser/backend/version.Version=testing'"
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
