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

  programs.zed = {
    enable = true;
    enableDefaults = true;
    settings = {
      language_models = {
        bedrock = {
          authentication_method = "named_profile";
          region = "us-west-2";
          profile = "bedrock";
          allow_extended_context = true;
        };
      };
      agent.default_model = {
        provider = "amazon-bedrock";
        model = "us.anthropic.claude-sonnet-4-6";
        effort = "max";
      };
      agent.tool_permissions = {
        tools = {
          terminal = {
            always_allow = [
              {pattern = "^git\\s+status(\\s|$)";}
              {pattern = "^git\\b";}
              {pattern = "^gt\\s+track(\\s|$)";}
            ];
          };
          "mcp:glyph:basic-memory__build_context" = {default = "allow";};
          "mcp:glyph:basic-memory__search_notes" = {default = "allow";};
        };
      };
    };
  };
}
