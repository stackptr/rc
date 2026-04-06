{
  config,
  llm-profile,
  pkgs,
  pkgs-stable-25-11,
  ...
}: {
  home.packages = [pkgs.mktorrent];

  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    web.enable = true;
    web.extraArgs = ["--port" "8890" "--hostname" "0.0.0.0"];
    rules = builtins.readFile "${llm-profile}/README.md";
    settings = {
      model = "anthropic/claude-opus-4-6";
      small_model = "anthropic/claude-haiku-4-5";
      enabled_providers = ["anthropic"];
      autoupdate = false;
      share = "disabled";
      plugin = ["${pkgs.opencode-claude-auth}"];
    };
  };

  systemd.user.services.opencode-web.Service.EnvironmentFile =
    config.age.secrets.opencode-env.path;

  age.secrets.opencode-env = {
    file = ../../home/secrets/opencode-env.age;
  };

  programs.beets = {
    enable = true;
    package = pkgs-stable-25-11.beets;
    settings = {
      directory = "/mnt/media/Music";
      import = {
        copy = true;
        move = false;
        write = true;
        replace = {
          # Default substitutions with extra escaping for Nix
          "[\\\\/]" = "_";
          "^\\." = "_";
          "[\\x00-\\x1f]" = "_";
          "[<>:\"\\?\\*\\|]" = "_";
          "\\.$" = "_";
          "\\s+$" = "";
          "^\\s+" = "";
          "^-" = "_";
          # Remove smart quotes
          "[\\u2018\\u2019]" = "\\'";
          "[\\u201c\\u201d]" = "\"";
        };
        languages = "en";
        timid = true;
      };
      paths = {
        default = "$albumartist/$album%aunique{}/%if{$multidisc,CD$disc0/}$track $title";
        comp = "Various Artists/$album%aunique{}/%if{$multidisc,CD$disc0/}$track $title";
      };
      match = {
        ignored_media = [
          "Hybrid SACD (SACD layer)"
          "Hybrid SACD (SACD layer, 2 channels)"
        ];
      };
      plugins = "musicbrainz discogs edit fetchart info inline";
      per_disc_numbering = true;
      item_fields = {
        multidisc = "1 if disctotal > 1 else 0";
        disc0 = "f\"{disc}\"";
      };
    };
  };

  programs.gallery-dl = {
    enable = true;
    settings = {
      extractor = {
        base-directory = "/mnt/archive/gallery-dl";
        archive = "/mnt/archive/gallery-dl/archive.sqlite3";
      };
    };
  };

  programs.rustmission = {
    enable = true;
    settings = {
      connection = {
        url = "http://glyph.rove-duck.ts.net:9091/transmission/rpc";
      };
    };
  };
}
