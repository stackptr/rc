{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    m-cli
    mas
    the-unarchiver
  ];

  homebrew = {
    enable = true;
    # N.B.: Removed entries in `masApps` require manual uninstallation
    masApps = {
      "Folder Quick Look" = 6753110395;
      "GoodLinks" = 1474335294;
      "Hand Mirror" = 1502839586;
      "Infuse" = 1136220934;
      "Mapper" = 1589391989;
      "Mela" = 1568924476;
      "Noir" = 1592917505;
      "Paku" = 1534130193;
      "Parcel" = 375589283;
      "Pixea" = 1507782672;
      "Play" = 1596506190;
      "Reeder" = 1529448980;
      "Timery" = 1425368544;
      "Things" = 904280696;
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
  rc.darwin.defaults.fastscripts = true;

  programs.iina = {
    enable = true;
  };

  programs.little-snitch = {
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
}
