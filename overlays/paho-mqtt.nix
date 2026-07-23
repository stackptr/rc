# paho-mqtt's test suite is flaky on client/broker teardown timing and
# intermittently fails CI (different tests fail each run, not a real
# regression). Tracked upstream, unresolved as of writing:
# https://github.com/NixOS/nixpkgs/issues/542586
final: prev: {
  pythonPackagesExtensions =
    prev.pythonPackagesExtensions
    ++ [
      (pyFinal: pyPrev: {
        # Its checks run in installCheckPhase (pyproject-style builder), not
        # checkPhase, so doCheck alone is a no-op here.
        paho-mqtt = pyPrev.paho-mqtt.overrideAttrs (old: {
          doCheck = false;
          doInstallCheck = false;
        });
      })
    ];
}
