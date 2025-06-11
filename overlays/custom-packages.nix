# Custom package definitions
# These are packages not available in nixpkgs or requiring customization
self: super: {
  # Claude desktop app
  claude-desktop = super.callPackage ./../packages/claude-desktop/package.nix {};

  # GitHub Desktop with custom configuration
  github-desktop = super.callPackage ./../packages/github-desktop/package.nix {};

  # FastScripts automation tool for macOS
  fastscripts = super.callPackage ./../packages/fastscripts/package.nix {};

  # Mochi spaced repetition software
  mochi = super.callPackage ./../packages/mochi/package.nix {};

  # Scroll Reverser for macOS trackpad settings
  scroll-reverser = super.callPackage ./../packages/scroll-reverser/package.nix {};

  # Transmission client alternative
  transmissionic = super.callPackage ./../packages/transmissionic/package.nix {};

  # Ungoogled Chromium with privacy enhancements
  ungoogled-chromium = super.callPackage ./../packages/ungoogled-chromium/package.nix {};
}
