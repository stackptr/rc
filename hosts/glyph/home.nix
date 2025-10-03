{pkgs, ...}: {
  programs.beets = {
    enable = true;
    package = pkgs.beets.override {
      pluginOverrides = {
        copyartifacts = {
          enable = true;
          propagatedBuildInputs = [pkgs.beetsPackages.copyartifacts];
        };
      };
    };
    settings = {
      directory = "/mnt/media/Music";
      # TODO: Backup ~/.config/beets/library.db
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
      };
      paths = {
        default = "$albumartist/$album%aunique{}/%if{$multidisc,CD$disc0/}$track $title";
        comp = "Various Artists/$album%aunique{}/%if{$multidisc,CD$disc0/}$track $title";
      };
      match = {
        ignored_media = [
          "Hybrid SACD (SACD layer)"
        ];
      };
      plugins = "copyartifacts discogs edit fetchart info inline";
      per_disc_numbering = true;
      copyartifacts = {
        extensions = ".* */*";
        print_ignored = true;
      };
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
