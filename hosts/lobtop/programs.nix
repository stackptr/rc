{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    m-cli
    mas
    the-unarchiver
  ];

  homebrew = {
    enable = true;
  };

  # CodexBar (cask in modules/darwin/rc.nix) reads Claude usage with the Claude
  # Code CLI's OAuth token, which only lobtop has: the other Macs use the desktop
  # app. The first key is Settings > Providers > Claude > "Allow reading Claude
  # Code's credentials". The prompt policy lets background refreshes ask for
  # Keychain access again after Claude Code rotates its token and drops the
  # grant; the default, onlyOnUserAction, fails quietly until a manual Refresh.
  # macOS's own Always Allow on the first prompt still has to be clicked once.
  system.defaults.CustomUserPreferences."com.steipete.codexbar" = {
    claudeOAuthDirectKeychainReadAllowed = true;
    claudeOAuthKeychainPromptMode = "always";
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

  programs.t3-code = {
    enable = true;
  };

  programs.things = {
    enable = true;
  };

  programs.zed = {
    enable = true;
    enableDefaults = true;
  };
}
