{
  config,
  pkgs,
  lib,
  allowVpn,
  ...
}: {
  homebrew = {
    enable = true;
    caskArgs.no_quarantine = true;
    onActivation = {
      cleanup = "zap";
      upgrade = true;
    };
    taps = builtins.attrNames config.nix-homebrew.taps; # See: zhaofengli/nix-homebrew#5
    # N.B.: Apps marked auto_updates will not be updated by homebrew. These apps should
    # have their updates disabled and then marked `greedy` to force homebrew to update.
    casks = let
      greedyApps =
        map (name: {
          inherit name;
          greedy = true;
        }) [
          "craft"
          "nova"
          "postico"
          "roon"
        ]
        ++ lib.optionals allowVpn ["tailscale-app"];
      otherApps = [
        "legcord"
        "plex" # auto_updates
        "textual"
      ];
    in
      lib.concatLists [
        greedyApps
        otherApps
      ];
    # N.B.: Removed entries in `masApps` require manual uninstallation
    masApps = {
      "Copilot" = 1447330651;
      "GoodLinks" = 1474335294;
      "Hand Mirror" = 1502839586;
      "Hush" = 1544743900;
      "Mapper" = 1589391989;
      "Mela" = 1568924476;
      "MusicBox" = 1614730313;
      "Numbers" = 409203825;
      "Noir" = 1592917505;
      "Pages" = 409201541;
      "Paku" = 1534130193;
      "Parcel" = 375589283;
      "Pixea" = 1507782672;
      "Play" = 1596506190;
      "Prompt" = 1594420480;
      "Reeder" = 1529448980;
      "Timery" = 1425368544;
      "Things" = 904280696;
      "Wipr" = 1320666476;
    };
  };
}
