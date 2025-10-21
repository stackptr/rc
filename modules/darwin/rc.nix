{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.rc.darwin.defaults;
in {
  options.rc.darwin.defaults = {
    fonts = mkEnableOption "Font defaults";

    homebrew = mkEnableOption "Homebrew defaults";

    fastscripts = mkEnableOption "FastScripts default userscripts";

    security = mkEnableOption "Security defaults";

    system = mkEnableOption "System defaults";
  };

  config = {
    fonts.packages = mkIf cfg.fonts [
      pkgs.nerd-fonts.meslo-lg # Supplies MesloLGSDZ: Line Gap Small, Dotted Zero
    ];

    homebrew = mkIf cfg.homebrew {
      caskArgs.no_quarantine = true;
      onActivation = {
        cleanup = "zap";
        upgrade = true;
      };
      taps = builtins.attrNames config.nix-homebrew.taps; # See: zhaofengli/nix-homebrew#5
    };

    programs.fastscripts = mkIf cfg.fastscripts {
      userScripts = {
        SafariQuitWithConfirmation = {
          source = pkgs.writeText "safari-quit-with-confirmation.applescript" (builtins.readFile ./fastscripts/safari-quit-with-confirmation.applescript);
          target = "Applications/Safari/Quit With Confirmation.applescript";
        };
      };
      plistFile = pkgs.writeText "fastscripts-keybindings.plist" (builtins.readFile ./fastscripts/keybindings.plist);
    };

    security.pam.services.sudo_local = mkIf cfg.security {
      reattach = true;
      touchIdAuth = true;
    };

    system.defaults = mkIf cfg.system {
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

      CustomUserPreferences = {
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
    };
  };
}
