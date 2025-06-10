{
  pkgs,
  pkgs-stable,
  lib,
  enableGuiPackages,
  showBatteryStatus,
  ...
}: {
  imports = [
    ./aws.nix
    ./starship.nix
    ./zsh.nix
  ];

  home.packages = with pkgs; let
    nodejs = pkgs-stable.nodejs_20;
    yarn = pkgs-stable.yarn.override {inherit nodejs;};
    development = [
      colima
      copilot-language-server
      docker
      hub
      jo
      nodejs
      shellcheck
      tree
      yarn
      yq
    ];
    nixSpecific = [
      comma
      manix
      nil
      nix-du
      nix-tree
      nix-your-shell
      statix
    ];
    tuiApps = [
      claude-code
      gitui
      git-interactive-rebase-tool
      lazydocker
    ];
    utilities = [
      coreutils-full
      fd
      ffmpeg_6
      mediainfo
      mktorrent
      mosh
      neofetch
      onefetch
      sox
      unzip
    ];
    guiApps = [code-cursor];
    darwinApps = [
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
      whatsapp-for-mac
      zoom-us
    ];
  in
    development
    ++ nixSpecific
    ++ tuiApps
    ++ utilities
    ++ lib.optionals enableGuiPackages guiApps
    ++ lib.optionals stdenv.isDarwin darwinApps;
  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  programs.bat = {
    enable = true;
    config = {
      theme = "Sublime Snazzy";
    };
  };

  programs.btop.enable = true;

  programs.chromium = {
    enable = enableGuiPackages;
    package = pkgs.ungoogled-chromium;
    extensions = let
      ublockOrigin = {id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";};
      reactDevTools = {id = "fmkadmapgofadopljbjfkapdkoienihi";};
    in [ublockOrigin reactDevTools];
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config = {
      global = {
        strict_env = true;
        hide_env_diff = true;
      };
    };
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
        theme = "fancy";
      };
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [catppuccin-nvim lualine-nvim];
    extraLuaConfig = ''
      require("catppuccin").setup {
        flavour = "mocha",
        color_overrides = {
            mocha = {
                base = "#000000",
                mantle = "#000000",
                crust = "#000000",
            },
        },
      }
      vim.cmd.colorscheme "catppuccin"
      require("lualine").setup {
          options = {
              theme = "catppuccin",
              component_separators = "",
              section_separators = { left = '', right = '' },
          }
      }
    '';
  };

  programs.nh.enable = true;

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

  programs.tmux = {
    enable = true;
    shortcut = "a";
    baseIndex = 1;
    mouse = true;
    terminal = "xterm-256color";
    sensibleOnTop = true;
    plugins = with pkgs;
      [
        {
          plugin = tmuxPlugins.continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '60' # minutes
          '';
        }
        {
          plugin = tmuxPlugins.catppuccin;
          extraConfig = ''
            set -g @catppuccin_flavor "mocha"

            # See: catppuccin/tmux#409
            set -g @catppuccin_window_status_style "custom"
            set -g @catppuccin_window_left_separator "#[bg=default,fg=#{@thm_surface_0}]#[bg=#{@thm_surface_0},fg=#{@thm_fg}]"
            set -g @catppuccin_window_right_separator "#[bg=default,fg=#{@thm_surface_0}]"
            set -g @catppuccin_window_current_left_separator "#[bg=default,fg=#{@thm_mauve}]#[bg=#{@thm_mauve},fg=#{@thm_bg}]"
            set -g @catppuccin_window_current_middle_separator "#[fg=#{@thm_mauve}]█"
            set -g @catppuccin_window_current_right_separator "#[bg=default,fg=#{@thm_surface_1}]"
            set -g @catppuccin_status_background "none"
          '';
        }
        {
          plugin = tmuxPlugins.cpu;
          # N.B.: extraConfig here applies to catppuccin above; it has to be set _after_ loading catppuccin plugin
          extraConfig = ''
            set -g status-right-length 100
            set -g status-left-length 100
            set -g status-left ""
            set -g status-right "#{E:@catppuccin_status_application}"
            set -ag status-right "#{E:@catppuccin_status_session}"
            set -agF status-right "#{E:@catppuccin_status_cpu}"
            set -ag status-right "#{E:@catppuccin_status_uptime}"
          '';
        }
        tmuxPlugins.yank
      ]
      ++ lib.optionals showBatteryStatus [
        {
          plugin = tmuxPlugins.battery;
          extraConfig = ''
            set -agF status-right "#{E:@catppuccin_status_battery}"
          '';
        }
      ];
    extraConfig = ''
      # See: tmux/tmux#696
      set-option -ga terminal-overrides ",xterm-256color:Tc"
      # Fix shell on startup, see: tmux/tmux#4166
      set -g default-command '$SHELL'
    '';
  };

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
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
    pinentry.package = with pkgs;
      if stdenv.isDarwin
      then pinentry_mac
      else pinentry-tty;
  };

  home.stateVersion = "23.11";
}
