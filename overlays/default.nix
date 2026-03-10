# Overlay management - consolidates all overlays for the repository
[
  # Custom packages defined in this repository
  (import ./custom-packages.nix)

  # Fix Daisydisk ahead of upstream
  (import ./daisydisk.nix)

  # Fix vendorHash for apoxy-dev golink fork
  (import ./golink.nix)
]
