{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    m-cli
    mas
    the-unarchiver
  ];

  homebrew = {
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

  programs.meetingbar = {
    enable = true;
    startOnActivation = true;
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
    installCask = false; # Kandji installs it
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
    enableNotifications = true;
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
