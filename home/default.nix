{
  pkgs,
  pkgs-stable,
  lib,
  hostname,
  enableGuiPackages,
  ...
}: {
  imports = [
    ./aws.nix
    ./zsh.nix
  ];

  home.packages = let
    nodejs = pkgs-stable.nodejs_20;
    yarn = pkgs-stable.yarn.override {inherit nodejs;};
  in
    with pkgs;
      [
        # Apps
        mosh
        neofetch
        onefetch
        ranger

        # Audio/video
        ffmpeg_6
        mediainfo
        sox

        # Development
        cachix
        colima
        code-cursor
        copilot-language-server
        coreutils-full
        docker
        fd
        gitui
        git-interactive-rebase-tool
        hub
        jo
        lazydocker
        nodejs
        shellcheck
        tree
        yarn
        yq

        # Nix
        alejandra
        comma
        manix
        nh
        nil
        nix-du
        nix-tree
        nix-your-shell
        statix

        # Utilities
        mktorrent
        unzip
      ]
      ++ lib.optionals stdenv.isDarwin [
        chatgpt
        daisydisk
        github-desktop
        gitify
        ice-bar
        iina
        m-cli
        mas
        mochi
        slack
        soundsource
        the-unarchiver
        ungoogled-chromium
        whatsapp-for-mac
        zoom-us
      ];
  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  programs.bat = {
    enable = true;
    config = {
      theme = "Sublime Snazzy";
    };
  };

  # TODO: Improve manner of per-host home-manager config
  programs.beets =
    if hostname == "glyph"
    then {
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
    }
    else {
      enable = false;
    };

  programs.btop.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.git = {
    enable = true;
    userName = "✿ corey";
    userEmail = "corey@x64.co";
    signing = {
      key = "F88C08579051AB48";
      signByDefault = true;
    };
    extraConfig = {
      sequence.editor = "interactive-rebase-tool";
      pull.rebase = true;
      push.autosetupremote = true;
      init.defaultBranch = "main";
      merge.conflictstyle = "zdiff3";
      rerere.enabled = true;
    };
  };

  programs.gpg = {
    enable = true;
  };

  programs.htop.enable = true;

  programs.jq.enable = true;

  programs.lsd = {
    enable = true;
    settings = {
      icons = {
        # TODO: "fancy" theme requires patched font with icons
        # https://github.com/lsd-rs/lsd#icons-not-showing-up
        theme = "unicode";
      };
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  programs.nushell.enable = true;

  programs.ripgrep.enable = true;

  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    matchBlocks = {
      "github.com" = {
        identityFile = "~/.ssh/id_ed25519";
      };
    };
    extraConfig = ''
      IgnoreUnknown UseKeychain
      UseKeychain yes
    '';
    includes = [
      "~/.colima/ssh_config"
    ];
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
        vimcmd_symbol = "[❮](green)";
      };
      git_status = {
        conflicted = "​";
        untracked = "​";
        modified = "​";
        staged = "​";
        renamed = "​";
        deleted = "​";
        stashed = "≡";
      };
      git_state = {
        format = "\([$state( $progress_current/$progress_total)]($style)\) ";
        style = "bright-black";
      };
      cmd_duration = {
        format = "[$duration]($style) ";
        style = "yellow";
      };
    };
  };

  programs.tmux = {
    enable = true;
    shortcut = "a";
    baseIndex = 1;
    mouse = true;
    terminal = "tmux-256color";
    plugins = with pkgs; [
      {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '60' # minutes
        '';
      }
      tmuxPlugins.yank
    ];
  };

  programs.yt-dlp.enable = true;

  programs.zed-editor = {
    enable = enableGuiPackages;
    extensions = [
      "haskell"
      "nix"
    ];
  };

  services.gpg-agent = {
    enable = true;
    enableZshIntegration = true;
    pinentry.package = pkgs.pinentry-tty;
  };

  home.stateVersion = "23.11";
}
