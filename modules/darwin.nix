{
  self,
  config,
  pkgs,
  ...
}: {
  fonts.fontDir.enable = true;
  fonts.fonts = [pkgs.fira-code-nerdfont];

  nixpkgs.config.allowUnfree = true;
  homebrew = {
    enable = true;
    caskArgs.no_quarantine = true;
    onActivation.cleanup = "zap";
    # N.B.: prefer casks to nixpkgs for placement in ~/Applications
    casks = [
      "apparency"
      "bartender"
      "daisydisk"
      "dash"
      "discord"
      "element"
      # "fastscripts" # TODO: Use pre-v3
      "github"
      "gitify"
      "google-chrome"
      "iina"
      "little-snitch"
      "notion"
      "nova"
      "popclip"
      "postico"
      "qlcolorcode"
      "qlimagesize"
      "qlmarkdown"
      "qlstephen"
      "qlvideo"
      "quicklook-json"
      "scroll-reverser"
      "signal"
      "slack"
      "soundsource"
      "suspicious-package"
      "tailscale"
      "the-unarchiver"
      "tripmode"
      "vlc"
      "whatsapp"
      "zoom"
    ];
    # N.B.: Removed entries in `masApps` require manual uninstallation
    masApps = {
      "Amphetamine" = 937984704;
      "Copilot" = 1447330651;
      "Day One" = 1055511498;
      "DeArrow" = 6451469297;
      "Flighty" = 1358823008;
      "Hand Mirror" = 1502839586;
      "Hush" = 1544743900;
      "Mapper" = 1589391989;
      "Mela" = 1568924476;
      "Messenger" = 1480068668;
      "MusicBox" = 1614730313;
      "MusicHarbor" = 1440405750;
      "Numbers" = 409203825;
      "Noir" = 1592917505;
      "Omnivore" = 1564031042;
      "Pages" = 409201541;
      "Paku" = 1534130193;
      "Parcel" = 639968404;
      "Paste" = 967805235;
      "Pixea" = 1507782672;
      "Play" = 1596506190;
      "Prompt" = 1594420480;
      "Reeder" = 1529448980;
      "SimpleScrobbler" = 495163497;
      "SponsorBlock" = 1573461917;
      "Timery" = 1425368544;
      "Things" = 904280696;
      "Toggl Track" = 1291898086;
      "Vinegar" = 1591303229;
      "Wipr" = 1320666476;
      "Xcode" = 497799835;
    };
    # TODO: pippo, Soundsource, TV Forecast
  };

  security.pam.enableSudoTouchIdAuth = true;

  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.defaults = {
    ".GlobalPreferences"."com.apple.mouse.scaling" = 1.5;
    LaunchServices.LSQuarantine = false;
    NSGlobalDomain = {
      AppleScrollerPagingBehavior = true; # Jump to spot on scroll bar when clicked
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false; # Disable smart quoting
      NSAutomaticSpellingCorrectionEnabled = false;
      "com.apple.springing.enabled" = true;
      "com.apple.springing.delay" = 0.5;
      # "com.apple.trackpad.forceClick" = 1; # TODO
      "com.apple.trackpad.scaling" = 1.0;

      # Always use expanded save panel
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;

      # Quickly repeat keys when held
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
    };
    # TODO:
    # showAppExposeGestureEnabled = 1;
    # showMissionControlGestureEnabled = 1;
    dock = {
      appswitcher-all-displays = false;
      autohide = false;
      mineffect = "scale";
      minimize-to-application = false;
      mru-spaces = false;
      orientation = "bottom";
      persistent-apps = [
        "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"
        "/System/Applications/Mail.app"
        "/Applications/Nova.app"
        "/Applications/Prompt.app"
        "/Applications/Reeder.app"
        "/Applications/Omnivore.app"
        "/System/Applications/Music.app"
        "/System/Applications/Calendar.app"
        "/Applications/Things3.app"
        "/System/Applications/Notes.app"
        "/System/Applications/Messages.app"
        "/Applications/Slack.app"
        "/Applications/GitHub Desktop.app"
      ];
      show-process-indicators = false;
      showhidden = false;
      show-recents = false;
      static-only = false;
      magnification = true;

      # Disable hot corners
      wvous-tl-corner = 1;
      wvous-bl-corner = 1;
      wvous-tr-corner = 1;
      wvous-br-corner = 1;
    };
    finder = {
      AppleShowAllFiles = false;
      ShowStatusBar = false;
      ShowPathbar = false;
      FXDefaultSearchScope = "SCcf"; # Search current folder first when searching
      FXPreferredViewStyle = "Nlsv"; # Prefer list view
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false; # Do not warn when changing file extensions
    };
    menuExtraClock = {
      ShowAMPM = true;
      ShowDayOfWeek = false;
      ShowDate = 0; # Show full date
    };
    screencapture.location = "~/Downloads";
    trackpad = {
      Clicking = true; # tap to click
      Dragging = true; # tap to drag
      TrackpadThreeFingerDrag = true;
    };
  };

  system.defaults.CustomUserPreferences = {
    "com.apple.desktopservices" = {
      DSDontWriteNetworkStores = true;
    };
    # Requires disabling SIP?
    # "com.apple.Safari" = {
    #   AutoOpenSafeDownloads = false; # Prevent opening "safe" files automatically
    #   ShowFullURLInSmartSearchField = false;
    #   ShowFavoritesBar = false;
    #   WebContinuousSpellCheckingEnabled = true;
    #   WebAutomaticSpellingCorrectionEnabled = false;
    #   WarnAboutFraudulentWebsites = true;
    #   "com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled" = false;

    #   # Develop menu
    #   IncludeDevelopMenu = true;
    #   WebKitDeveloperExtrasEnabledPreferenceKey = true;
    #   "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" = true;

    #   # TODO: Set "compact" tab layout
    # };
    "com.pilotmoon.popclip" = {
      CombinedItemOrder = [
        "openlink"
        "search"
        "cut"
        "copy"
        "paste"
        "revealfile"
        "lookup"
        "ext-com.pilotmoon.popclip.extension.parcel"
        "openmail"
      ];
      HasShownWelcome = true;
      NMStatusItemHideIcon = true;
      "extension#com.pilotmoon.popclip.builtin-search#template" = "https://kagi.com/search?q=***";
    };
    "com.pilotmoon.scroll-reverser" = {
      InvertScrollingOn = true;
      ReverseTrackpad = false;
      ReverseMouse = true;
      ReverseY = true;
      StartAtLogin = true;
    };
  };

  system.activationScripts.postUserActivation.text = ''
    popclipExtPlist=~/Library/Application\ Support/PopClip/Extensions/Extensions.plist
    if test -f "$popclipExtPlist"; then
      if [[ ! `defaults read "$popclipExtPlist" "Installed Extensions"` =~ "Parcel.popclipext" ]]; then
        echo "installing popclip parcel extension..." >&2
        pkill PopClip || true # Kill process if needed; don't exit if command fails
        temp=$(mktemp -d)
        curl -s --output-dir "$temp" https://pilotmoon.com/popclip/extensions/ext/Parcel.popclipextz -O
        open "$temp/Parcel.popclipextz"
        sleep 2 # Allow extension to install before starting PopClip below
        rm -r "$temp"
      fi
    fi

    echo "starting utilties..." >&2
    pgrep -q Bartender\ 5 || open /Applications/Bartender\ 5.app/
    pgrep -q Gitify || open /Applications/Gitify.app/
    pgrep -q Hand\ Mirror || open /Applications/Hand\ Mirror.app/
    pgrep -q Little\ Snitch || open /Applications/Little\ Snitch.app/
    pgrep -q PopClip || open /Applications/PopClip.app/
    pgrep -q Scroll\ Reverser || open /Applications/Scroll\ Reverser.app/
    pgrep -q SoundSource || open /Applications/SoundSource.app/
    pgrep -q Tailscale || open /Applications/Tailscale.app/
  '';

  # TODO: Keyboard shortcuts, see LnL7/nix-darwin#699
  # system.keyboard.shortcuts = let
  #   cmdOptLeft = {
  #     mods = {
  #       option = true;
  #       command = true;
  #     };
  #     key = "left";
  #   };
  #   cmdOptRight = {
  #     mods = {
  #       option = true;
  #       command = true;
  #     };
  #     key = "right";
  #   };
  # in {
  #   enable = true;
  #   appShortcuts = {
  #     "Preview.app" = {
  #       "Show Previous Tab" = cmdOptLeft;
  #       "Show Next Tab" = cmdOptRight
  #     };
  #     "Finder.app" = {
  #       "Show Previous Tab" = cmdOptLeft;
  #       "Show Next Tab" = cmdOptRight
  #     };
  #     "Prompt.app" = {
  #       "Show Previous Tab" = cmdOptLeft;
  #       "Show Next Tab" = cmdOptRight
  #     };
  #     "Mail.app" = {
  #       "Archive" = {
  #         key = "right";
  #       };
  #     };
  #     "Nova.app" = {
  #       "Show Previous Tab" = cmdOptLeft;
  #       "Show Next Tab" = cmdOptRight
  #     };
  #   };
  # };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;
}
