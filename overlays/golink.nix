# Fix vendorHash for apoxy-dev golink fork
final: prev: {
  golink = prev.golink.overrideAttrs (old: {
    goModules = old.goModules.overrideAttrs {
      outputHash = "sha256-M3Qm25KF6gWtp3K1SigLucgrIJ+5KokMq+Bp7XXaE+o=";
    };
  });
}
