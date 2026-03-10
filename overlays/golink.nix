# Fix vendorHash for apoxy-dev golink fork
final: prev: {
  golink = prev.golink.overrideAttrs {
    vendorHash = "sha256-M3Qm25KF6gWtp3K1SigLucgrIJ+5KokMq+Bp7XXaE+o=";
  };
}
