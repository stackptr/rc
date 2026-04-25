{
  lib,
  fetchFromGitHub,
  buildGoModule,
  nix-update-script,
}:
buildGoModule {
  pname = "things3-cli";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "ossianhempel";
    repo = "things3-cli";
    rev = "v0.2.0";
    hash = "sha256-1YBBOYaCrP7/K1ADJter+iEETNk57Z6UMZY4/+F5iKw=";
  };

  vendorHash = "sha256-tN903swhctln5f23UQvjdHfLnunzah4Jr+NdsEHG3nI=";

  # Tests require Things 3 database and app running on macOS
  doCheck = false;

  passthru.updateScript = nix-update-script {};

  meta = with lib; {
    description = "CLI for Things 3 by Cultured Code, implemented in Go";
    homepage = "https://github.com/ossianhempel/things3-cli";
    license = licenses.mit;
    mainProgram = "things";
    platforms = platforms.darwin;
  };
}
