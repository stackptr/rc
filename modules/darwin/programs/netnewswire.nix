{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.netnewswire;
in {
  options.programs.netnewswire = {
    enable = mkEnableOption "NetNewsWire";
  };

  # The cask rather than nixpkgs' net-news-wire, which trails upstream releases
  # by weeks. The app updates itself with Sparkle; greedy lets Homebrew upgrade
  # it too.
  config = mkIf cfg.enable {
    homebrew.casks = [
      {
        name = "netnewswire";
        greedy = true;
      }
    ];
  };
}
