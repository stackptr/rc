{
  config,
  llm-profile,
  pkgs,
  ...
}: let
  stromaModel = "qwen3.8-27b-mtplx-optimized-quality";
in {
  home.packages = [pkgs.mktorrent pkgs.obsidian-headless];

  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    web.enable = true;
    web.extraArgs = ["--port" "8890" "--hostname" "0.0.0.0"];
    # A shorter prompt helps a 27B model more than it helps Claude.
    context = (import ../../lib/llm-profile.nix llm-profile).agent;
    settings = {
      model = "stroma/${stromaModel}";
      small_model = "stroma/${stromaModel}";
      enabled_providers = ["stroma"];
      autoupdate = false;
      share = "disabled";
      provider.stroma = {
        npm = "@ai-sdk/openai-compatible";
        name = "Stroma";
        options.baseURL = "https://stroma.note-iwato.ts.net/v1";
        models.${stromaModel}.name = "Qwen 3.8 27B";
      };
    };
  };

  systemd.user.services.opencode-web.Service.EnvironmentFile =
    config.age.secrets.opencode-env.path;

  age.secrets.opencode-env = {
    file = ../../home/secrets/opencode-env.age;
  };

  programs.beets = {
    enable = true;
    settings = {
      directory = "/mnt/media/Music";
      # Extend beets' default ignore list to skip playlist files on import
      ignore = [
        ".*"
        "*~"
        "System Volume Information"
        "lost+found"
        "*.m3u"
        "*.m3u8"
      ];
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
        url = "http://glyph.note-iwato.ts.net:9091/transmission/rpc";
      };
    };
  };
}
