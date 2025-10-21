{
  self,
  config,
  pkgs,
  lib,
  username,
  ...
}: {
  imports = [
    ./programs
    ./system
  ];

  fonts.packages = [
    pkgs.nerd-fonts.meslo-lg # Supplies MesloLGSDZ: Line Gap Small, Dotted Zero
  ];

  home-manager.users.${username} = {...}: {
    imports = [./home.nix];
  };

  homebrew = {
    enable = true;
    caskArgs.no_quarantine = true;
    onActivation = {
      cleanup = "zap";
      upgrade = true;
    };
    taps = builtins.attrNames config.nix-homebrew.taps; # See: zhaofengli/nix-homebrew#5
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

  programs.fastscripts = {
    enable = true;
    userScripts = {
      SafariQuitWithConfirmation = {
        source = pkgs.writeText "safari-quit-with-confirmation.applescript" (builtins.readFile ./fastscripts/safari-quit-with-confirmation.applescript);
        target = "Applications/Safari/Quit With Confirmation.applescript";
      };
    };
    plistFile = pkgs.writeText "fastscripts-keybindings.plist" (builtins.readFile ./fastscripts/keybindings.plist);
    startOnActivation = true;
  };

  programs.iina = {
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

  security.pam.services.sudo_local = {
    reattach = true;
    touchIdAuth = true;
  };

  system.disableUpdates = [
    "com.daisydiskapp.DaisyDiskStandAlone"
    "org.sbarex.QLMarkdown"
    {
      domain = "at.obdev.littlesnitch.softwareupdate";
      keys = ["SoftwareUpdateCheckAutomatically"];
    }
  ];

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

    # N.B.: Terminal requires Full Disk Access to apply Safari defaults
    "com.apple.Safari" = {
      AutoOpenSafeDownloads = false; # Prevent opening "safe" files automatically
      ShowFullURLInSmartSearchField = false;
      "ShowFavoritesBar-v2" = false;
      IncludeDevelopMenu = true;
      WebKitDeveloperExtrasEnabledPreferenceKey = true;
    };
  };

  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Auto upgrade nix package and the daemon service.
  nix.enable = true;
  nix.package = pkgs.nix;
}
