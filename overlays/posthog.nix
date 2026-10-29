# nixpkgs marks posthog broken when mcp >= 2, but mcp is only one of its test
# inputs: its tests fail, not the library. Open WebUI needs it (through
# chromadb), so skip the tests and clear the flag. Remove once nixpkgs fixes
# posthog (meta.broken = lib.versionAtLeast mcp.version "2").
final: prev: {
  pythonPackagesExtensions =
    prev.pythonPackagesExtensions
    ++ [
      (pyFinal: pyPrev: {
        # Checks run in installCheckPhase (pyproject-style builder), so both
        posthog = pyPrev.posthog.overrideAttrs (old: {
          doCheck = false;
          doInstallCheck = false;
          meta = old.meta // {broken = false;};
        });
      })
    ];
}
