# mactop 2.1.6 reads CPU, DRAM, ANE and system power on M5 Max and M5 Ultra
# (metaspartan/mactop#98). 2.1.5, in nixpkgs, reports 0 W for all of them
# on Stroma. Go dependencies are unchanged, so vendorHash carries over.
# Drop once nixpkgs has 2.1.6 or later.
final: prev: {
  mactop = prev.mactop.overrideAttrs (old: rec {
    version = "2.1.6";
    src = prev.fetchFromGitHub {
      owner = "metaspartan";
      repo = "mactop";
      tag = "v${version}";
      hash = "sha256-hFceT6ZHv8Iyhe3jqp1qTQRPPGeQmpGXN4cE6bs4P5E=";
    };
  });
}
