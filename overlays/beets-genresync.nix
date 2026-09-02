# Enable the external genresync plugin, following the third-party plugin
# pattern documented at the top of nixpkgs' python3Packages.beets package.nix.
final: prev: {
  pythonPackagesExtensions =
    prev.pythonPackagesExtensions
    ++ [
      (pyFinal: pyPrev: {
        beets-genresync = pyFinal.callPackage ../packages/beets-genresync/package.nix {};

        # Skip beets' full pytest suite on every plugin-config change.
        beets = pyPrev.beets.override {
          doCheck = false;
          pluginOverrides = {
            genresync = {
              enable = true;
              propagatedBuildInputs = [pyFinal.beets-genresync];
            };
          };
        };
      })
    ];

  beets = final.python3.pkgs.toPythonApplication final.python3.pkgs.beets;
}
