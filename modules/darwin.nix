{
  self,
  config,
  pkgs,
  lib,
  allowVpn,
  ...
}: {
  fonts.packages = [pkgs.nerd-fonts.fira-code];

  homebrew = {
    enable = true;
    caskArgs.no_quarantine = true;
    onActivation = {
      cleanup = "zap";
      upgrade = true;
    };
    taps = builtins.attrNames config.nix-homebrew.taps; # See: zhaofengli/nix-homebrew#5
    casks = let
      # Electron apps generally are marked auto_updates
      electronApps = [
        "github"
      ];
      # Apps marked auto_updates but which have their updates disabled via CustomUserPreferences
      greedyApps =
        map (name: {
          inherit name;
          greedy = true;
        }) [
          "jordanbaird-ice" # Bartender replacement
          "nova"
          "popclip"
          "postico"
          "qlmarkdown"
        ]
        ++ lib.optionals allowVpn ["tailscale"];
      # TODO: casks marked as auto_updates should be set as greedy with auto update setting disabled
      otherApps = [
        "craft" # auto_updates
        "eloston-chromium"
        # "fastscripts" # TODO: Use pre-v3
        "legcord"
        #"mochi"
        "qlcolorcode"
        "qlstephen"
        "quicklook-json"
        "roon" # auto_updates
        "scroll-reverser"
        "textual"
        "zoom" # auto_updates
      ];
    in
      lib.concatLists [
        electronApps
        greedyApps
        otherApps
      ];
    # N.B.: Removed entries in `masApps` require manual uninstallation
    masApps = {
      "Consent-O-Matic" = 1606897889;
      "Copilot" = 1447330651;
      "Day One" = 1055511498;
      "DeArrow" = 6451469297;
      "Flighty" = 1358823008;
      "Flow" = 1423210932;
      "GoodLinks" = 1474335294;
      "Hand Mirror" = 1502839586;
      "Hush" = 1544743900;
      "Kiwix" = 997079563;
      "Mapper" = 1589391989;
      "Messenger" = 1480068668;
      "MusicBox" = 1614730313;
      "MusicHarbor" = 1440405750;
      "Numbers" = 409203825;
      "Noir" = 1592917505;
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
  };

  security.pam.services.sudo_local.touchIdAuth = true;

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
        "/Applications/Roon.app"
        "/System/Applications/Calendar.app"
        "/Applications/Things3.app"
        "/System/Applications/Notes.app"
        "/Applications/Craft.app"
        "/System/Applications/Messages.app"
        "${pkgs.slack}/Applications/Slack.app"
        "/Applications/Textual.app"
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

    # Disable automatic updates for casks above marked greedy
    # See: https://github.com/sparkle-project/Sparkle/blob/2.x/Sparkle/SUConstants.m
    "at.eggerapps.Postico" = {
      SUEnableAutomaticChecks = false;
      SUAutomaticallyUpdate = false;
    };
    "at.obdev.littlesnitch.softwareupdate".SoftwareUpdateCheckAutomatically = false; # N.B.: Does not use Sparkle for updates
    "ch.tripmode.TripMode".SUEnableAutomaticChecks = {
      SUEnableAutomaticChecks = false;
      SUAutomaticallyUpdate = false;
    };
    "com.colliderli.iina".SUEnableAutomaticChecks = false;
    "com.daisydiskapp.DaisyDiskStandAlone".SUEnableAutomaticChecks = false;
    "com.jordanbaird.Ice" = {
      SUEnableAutomaticChecks = false;
      SUAutomaticallyUpdate = false;
    };
    "com.kapeli.dashdoc".SUEnableAutomaticChecks = false;
    "com.luckymarmot.Paw".SUEnableAutomaticChecks = false;
    "com.panic.Nova" = {
      SUEnableAutomaticChecks = false;
      SUAutomaticallyUpdate = false;
    };
    "com.pilotmoon.popclip".SUEnableAutomaticChecks = false;
    "com.rogueamoeba.soundsource" = {
      SUEnableAutomaticChecks = false;
      SUAutomaticallyUpdate = false;
    };
    "io.tailscale.ipn.macsys".SUEnableAutomaticChecks = false;
    "jp.tmkk.XLD".SUEnableAutomaticChecks = false;
    "org.sbarex.QLMarkdown".SUEnableAutomaticChecks = false;
    "org.videolan.vlc".SUEnableAutomaticChecks = false;
  };

  system.activationScripts.postUserActivation.text =
    ''
      popclipExtPlist=~/Library/Application\ Support/PopClip/Extensions/Extensions.plist
      if test -f "$popclipExtPlist"; then
        if [[ ! $(defaults read "$popclipExtPlist" "Installed Extensions") == *"Parcel.popclipext"* ]]; then
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
      pgrep -q Ice || open /Applications/Ice.app/
      pgrep -q Gitify || open ${pkgs.gitify}/Applications/Gitify.app/
      pgrep -q Hand\ Mirror || open /Applications/Hand\ Mirror.app/
      pgrep -q PopClip || open /Applications/PopClip.app/
      pgrep -q Scroll\ Reverser || open /Applications/Scroll\ Reverser.app/
      pgrep -q SoundSource || open ${pkgs.soundsource}/Applications/SoundSource.app/
    ''
    + (
      if allowVpn
      then ''
        pgrep -q Tailscale || open /Applications/Tailscale.app/
      ''
      else ""
    );

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
  nix.enable = true;
  nix.package = pkgs.nix;
}
