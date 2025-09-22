# Overlay management - consolidates all overlays for the repository
[
  # Custom packages defined in this repository
  (import ./custom-packages.nix)

  # Application-specific overlays for version pinning/customization
  (import ./gallery-dl.nix)
]
