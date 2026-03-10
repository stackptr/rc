# Rebuild golink from apoxy-dev fork source with correct vendorHash
final: prev: {
  golink = prev.buildGo125Module {
    pname = "golink";
    inherit (prev.golink) version src ldflags;
    vendorHash = "sha256-M3Qm25KF6gWtp3K1SigLucgrIJ+5KokMq+Bp7XXaE+o=";
  };
}
