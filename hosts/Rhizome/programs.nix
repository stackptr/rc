{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    m-cli
    mas
    secretive
    mochi
    the-unarchiver
  ];

  homebrew = {
    enable = true;
    casks = [
      "dash"
      "legcord"
      "textual"
      "zoom"
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

  programs.netnewswire = {
    enable = true;
  };

  programs.obsidian = {
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

  programs.ykding.enable = true;

  programs.scroll-reverser = {
    enable = true;
    startOnActivation = true;
  };

  programs.slack = {
    enable = true;
  };

  programs.soundsource = {
    enable = true;
    startOnActivation = true;
  };

  programs.cmux = {
    enable = true;
    enableDefaults = true;
  };

  programs.codexbar = {
    enable = true;
    startOnActivation = true;
  };

  programs.t3-code = {
    enable = true;
    enableDefaults = true;
  };

  programs.things = {
    enable = true;
  };

  programs.zed = {
    enable = true;
    enableDefaults = true;
  };
}
