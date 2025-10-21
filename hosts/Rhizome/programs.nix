{
  config,
  pkgs,
  ...
}: {
  homebrew = {
    enable = true;
    casks = [
      "legcord"
      "plex"
      "textual"
    ];
    # N.B.: Removed entries in `masApps` require manual uninstallation
    masApps = {
      "Copilot" = 1447330651;
      "Folder Quick Look" = 6753110395;
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

  programs.craft = {
    enable = true;
  };

  programs.daisydisk = {
    enable = true;
  };

  programs.fastscripts = {
    enable = true;
    startOnActivation = true;
  };

  programs.iina = {
    enable = true;
  };

  programs.little-snitch = {
    enable = true;
  };

  programs.nova-editor = {
    enable = true;
  };

  programs.popclip = {
    enable = true;
    startOnActivation = true;
  };

  programs.postico = {
    enable = true;
  };

  programs.roon = {
    enable = true;
  };

  programs.scroll-reverser = {
    enable = true;
    startOnActivation = true;
  };

  programs.soundsource = {
    enable = true;
    startOnActivation = true;
  };

  programs.tailscale = {
    enable = true;
    startOnActivation = true;
  };
}
