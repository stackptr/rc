{
  lib,
  buildNpmPackage,
  fetchurl,
  python3,
  nodejs_22,
}:
buildNpmPackage rec {
  pname = "obsidian-headless";
  version = "0.0.8";

  src = fetchurl {
    url = "https://registry.npmjs.org/obsidian-headless/-/obsidian-headless-${version}.tgz";
    hash = "sha256-+fg6tr69/7n73KhlJxAb4ujMOvH64hLwIt/6MeAiNtU=";
  };

  # Tarball extracts to ./package/; lock file is vendored alongside this derivation
  sourceRoot = "package";

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-gp8dLJ0ACb1jaXcmRq6/+0VygNu0LNtmdl/wws0M8EY=";

  nodejs = nodejs_22;

  nativeBuildInputs = [python3];

  dontNpmBuild = true;

  postInstall = ''
    chmod +x $out/lib/node_modules/obsidian-headless/cli.js
  '';

  meta = with lib; {
    description = "Headless client for Obsidian Sync";
    homepage = "https://obsidian.md";
    license = licenses.unfree;
    maintainers = [];
    mainProgram = "ob";
    platforms = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
  };
}
