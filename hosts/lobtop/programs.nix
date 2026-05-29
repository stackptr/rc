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

  programs.daisydisk = {
    enable = true;
  };

  programs.karabiner = {
    enable = true;
    startOnActivation = true;
    # MX Master 4 M (Logitech) — vendor 1133, product 45122
    devices = [
      {
        identifiers = {
          is_pointing_device = true;
          product_id = 45122;
          vendor_id = 1133;
        };
        ignore = false;
      }
    ];
    complexModifications = [
      {
        description = "Mission control";
        manipulators = [
          {
            type = "basic";
            from.pointing_button = "button7";
            to = [{key_code = "mission_control";}];
          }
        ];
      }
      {
        description = "Thumb button → Right space";
        manipulators = [
          {
            type = "basic";
            from.pointing_button = "button4";
            to = [
              {
                key_code = "right_arrow";
                modifiers = ["control"];
              }
            ];
          }
        ];
      }
      {
        description = "Thumb button → Left space";
        manipulators = [
          {
            type = "basic";
            from.pointing_button = "button5";
            to = [
              {
                key_code = "left_arrow";
                modifiers = ["control"];
              }
            ];
          }
        ];
      }
    ];
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
    enableDefaults = true;
  };
}
