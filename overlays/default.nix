# Overlay management - consolidates all overlays for the repository
[
  # Custom packages defined in this repository
  (import ./custom-packages.nix)

  # Addresses issue with systemd on zeta
  (import ./systemd-with-bridge.nix)
]
