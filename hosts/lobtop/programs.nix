{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    m-cli
    mas
    the-unarchiver
  ];

  homebrew = {
    enable = true;
    casks = [
      "meetingbar"
    ];
    # N.B.: Removed entries in `masApps` require manual uninstallation
    masApps = {
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

  programs.cmux = {
    enable = true;

    settings = {
      app.minimalMode = true;
      notifications.showInMenuBar = false;
      ui.surfaceTabBar.buttons = [
        "cmux.newTerminal"
        "cmux.splitRight"
        "cmux.splitDown"
      ];
      workspaceColors = {
        notificationBadgeColor = null;
        indicatorStyle = "leftRail";
        selectionColor = null;
        colors = {
          Red = "#ff7b72";
          Orange = "#ffa657";
          Green = "#7ee787";
          Blue = "#79c0ff";
          Sky = "#a5d6ff";
          Purple = "#d2a8ff";
          Pink = "#ff6ac1";
          Cyan = "#9aedfe";
        };
      };
      shortcuts.bindings = {
        openFolder = "";
        reopenPreviousSession = "";
        goToWorkspace = "cmd+o";
        commandPalette = "cmd+p";
        nextSurface = "cmd+opt+→";
        prevSurface = "cmd+opt+←";
        nextSidebarTab = "cmd+opt+↓";
        prevSidebarTab = "cmd+opt+↑";
        closeOtherTabsInPane = "";
        selectSurfaceByNumber = "cmd+1";
        selectWorkspaceByNumber = "ctrl+1";
      };
    };

    ghostty = {
      settings = {
        background = "#131313";
        foreground = "#dddddd";
        "cursor-color" = "#dddddd";
        "selection-background" = "#353436";
        "selection-foreground" = "#dddddd";
        "font-family" = "MesloLGSDZ Nerd Font Mono";
        "font-size" = 12;
        "window-padding-x" = 8;
        "window-padding-y" = 8;
      };
      palette = {
        "0" = "#131313";
        "1" = "#ff5c57";
        "2" = "#5af78e";
        "3" = "#f3f99d";
        "4" = "#57c7ff";
        "5" = "#ff6ac1";
        "6" = "#9aedfe";
        "7" = "#caccca";
        "8" = "#686868";
        "9" = "#ff7b72";
        "10" = "#7ee787";
        "11" = "#ffa657";
        "12" = "#79c0ff";
        "13" = "#d2a8ff";
        "14" = "#a5d6ff";
        "15" = "#ffffff";
      };
    };
  };
}
