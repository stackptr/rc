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
    casks = [
      "legcord"
    ];
  };

  programs.chromium = {
    enable = true;
    package = pkgs.ungoogled-chromium;
    extensions = let
      cookiesTxtLocally = "cclelndahbckbenkjhflpdbgdldlbecc";
      ublockOrigin = "cjpalhdlnbpafiamejdnhcphjbkeiagm";
      reactDevTools = "fmkadmapgofadopljbjfkapdkoienihi";
    in [cookiesTxtLocally ublockOrigin reactDevTools];
  };

  programs.cmux = {
    enable = true;
    enableDefaults = true;
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
