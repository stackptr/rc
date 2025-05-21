self: super: {
  github-desktop = super.callPackage ./../packages/github-desktop/package.nix {};
  fastscripts = super.callPackage ./../packages/fastscripts/package.nix {};
  mochi = super.callPackage ./../packages/mochi/package.nix {};
  scroll-reverser = super.callPackage ./../packages/scroll-reverser/package.nix {};
  transmissionic = super.callPackage ./../packages/transmissionic/package.nix {};
  ungoogled-chromium = super.callPackage ./../packages/ungoogled-chromium/package.nix {};
}
