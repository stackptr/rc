self: super: {
  github-desktop = super.callPackage ./../packages/github-desktop/package.nix {};
  ungoogled-chromium = super.callPackage ./../packages/ungoogled-chromium/package.nix {};
}
