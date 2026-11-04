# Scroll Reverser 2.1.1, ahead of nixpkgs (1.9). Since 2.0, releases are on
# GitHub. Drop once nixpkgs has 2.1.1 or later.
final: prev: {
  scroll-reverser = prev.scroll-reverser.overrideAttrs (finalAttrs: old: {
    version = "2.1.1";
    src = prev.fetchurl {
      url = "https://github.com/pilotmoon/Scroll-Reverser/releases/download/v${finalAttrs.version}/ScrollReverser-${finalAttrs.version}.zip";
      hash = "sha256-ZUoruzaPOc98qa3LTYPBLFcvLGSIbvUBKUmv2Bz2lpE=";
    };
  });
}
