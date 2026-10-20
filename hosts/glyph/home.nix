{
  osConfig,
  pkgs,
  ...
}: {
  home.packages = [pkgs.mktorrent pkgs.obsidian-headless];

  # `just switch-remote spore` and the tailnet-lockout tunnel log in to spore
  # and zeta as root with glyph's client key, decrypted by agenix at boot.
  programs.ssh.matchBlocks."spore zeta *.note-iwato.ts.net" = {
    identityFile = osConfig.age.secrets.ssh-client-key.path;
    identitiesOnly = true;
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
