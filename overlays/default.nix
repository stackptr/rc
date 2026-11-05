# Overlay management - consolidates all overlays for the repository
[
  # Custom packages defined in this repository
  (import ./custom-packages.nix)

  # Fix Daisydisk ahead of upstream
  (import ./daisydisk.nix)

  # Skip paho-mqtt's flaky test suite (nixpkgs#542586)
  (import ./paho-mqtt.nix)

  # posthog is marked broken over a test-only input; Open WebUI needs it
  (import ./posthog.nix)

  # Link alloy against full systemd so it can read zstd journals
  (import ./grafana-alloy.nix)

  # mactop 2.1.6 for M5 Ultra power readings, ahead of nixpkgs
  (import ./mactop.nix)

  # Scroll Reverser 2.1.1, ahead of nixpkgs
  (import ./scroll-reverser.nix)

  # Correct opencode's Linux node_modules hash, fixed on nixpkgs master
  (import ./opencode.nix)
]
