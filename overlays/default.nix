# Overlay management - consolidates all overlays for the repository
[
  # Custom packages defined in this repository
  (import ./custom-packages.nix)

  # Fix Daisydisk ahead of upstream
  (import ./daisydisk.nix)

  # Override opencode ahead of nixpkgs pin
  (import ./opencode.nix)
]
