{
  pkgs,
  pkgs-stable,
  lib,
  enableGuiPackages,
  ...
}: {
  imports = [
    ./aws.nix
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

  programs.lf.enable = true;

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

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      format = lib.concatStrings [
        "[](color_orange)"
        "$os"
        "$username$hostname"
        "[](bg:color_yellow fg:color_orange)"
        "$directory"
        "[](fg:color_yellow bg:color_aqua)"
        "$git_branch"
        "$git_status"
        "[](fg:color_aqua bg:color_blue)"
        "$nix_shell"
        "$c"
        "$rust"
        "$golang"
        "$nodejs"
        "$haskell"
        "$python"
        "[](fg:color_blue bg:color_bg3)"
        "$direnv"
        "$docker_context"
        "[](fg:color_bg3 bg:color_bg1)"
        "$time"
        "$cmd_duration"
        "[ ](fg:color_bg1)"
        "$battery"
        "$line_break$character"
      ];
      palette = "gruvbox_dark";
      palettes.gruvbox_dark = {
        color_fg0 = "#fbf1c7";
        color_fg1 = "#fbded0";
        color_bg1 = "#3c3836";
        color_bg3 = "#665c54";
        color_blue = "#458588";
        color_aqua = "#689d6a";
        color_green = "#98971a";
        color_orange = "#d65d0e";
        color_purple = "#b16286";
        color_red = "#cc241d";
        color_yellow = "#d79921";
      };
      os = {
        disabled = false;
        style = "bg:color_orange fg:color_fg0";
      };
      os.symbols = {
        Windows = "󰍲";
        Ubuntu = "󰕈";
        SUSE = "";
        Raspbian = "󰐿";
        Mint = "󰣭";
        Macos = "󰀵";
        Manjaro = "";
        Linux = "󰌽";
        Gentoo = "󰣨";
        Fedora = "󰣛";
        Alpine = "";
        Amazon = "";
        Android = "";
        Arch = "󰣇";
        Artix = "󰣇";
        EndeavourOS = "";
        CentOS = "";
        Debian = "󰣚";
        Redhat = "󱄛";
        RedHatEnterprise = "󱄛";
        NixOS = "󱄅";
      };
      username = {
        show_always = true;
        style_user = "bg:color_orange fg:color_fg0";
        style_root = "bg:color_orange fg:color_fg0";
        format = "[ $user]($style)";
      };
      hostname = {
        ssh_only = false;
        format = "[@$hostname ]($style)";
        style = "bg:color_orange fg:color_fg0";
        disabled = false;
      };
      directory = {
        style = "fg:color_fg0 bg:color_yellow";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncate_to_repo = true;
        truncation_symbol = "…/";
      };
      directory.substitutions = {
        "Applications" = " ";
        "Development" = " ";
        "Documents" = "󰈙 ";
        "Downloads" = " ";
        "Music" = "󰝚 ";
        "Pictures" = " ";
        "github" = " ";
      };
      git_branch = {
        symbol = "";
        style = "bg:color_aqua";
        format = "[[ $symbol $branch](fg:color_fg0 bg:color_aqua)]($style)";
      };
      git_status = {
        style = "bg:color_aqua";
        format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](fg:color_fg1 bg:color_aqua) [($ahead_behind$stashed) ](fg:color_fg0 bg:color_aqua)]($style)";
        conflicted = "​";
        untracked = "​";
        modified = "​";
        staged = "​";
        renamed = "​";
        deleted = "​";
        stashed = "≡";
      };
      nix_shell = {
        symbol = "󱄅";
        style = "bg:color_blue";
        impure_msg = "";
        format = "[[ $symbol( $name) ](fg:color_fg0 bg:color_blue)]($style)";
      };
      nodejs = {
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };
      c = {
        symbol = " ";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };
      rust = {
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };
      golang = {
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };
      haskell = {
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };
      python = {
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };
      direnv = {
        disabled = false;
        symbol = "󱁿 direnv";
        style = "bg:color_bg3";
        format = "[[ $symbol( $loaded($allowed)) ](fg:#83a598 bg:color_bg3)]($style)";
        allowed_msg = "";
        not_allowed_msg = "";
        denied_msg = "";
        loaded_msg = "loaded";
        unloaded_msg = "";
      };
      docker_context = {
        symbol = "";
        style = "bg:color_bg3";
        format = "[[ $symbol( $context) ](fg:#83a598 bg:color_bg3)]($style)";
      };
      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:color_bg1";
        format = "[[  $time ](fg:color_fg0 bg:color_bg1)]($style)";
      };
      cmd_duration = {
        style = "bg:color_bg1";
        format = "[[  $duration ](fg:color_fg0 bg:color_bg1)]($style)";
      };
      battery = {
        disabled = false;
        full_symbol = "󰁹 ";
        charging_symbol = "󰂄 ";
        discharging_symbol = "󰂃 ";
        unknown_symbol = "󰁽 ";
        empty_symbol = "󰂎 ";
        format = "[ $symbol]($style) ";
      };
      character = {
        success_symbol = "[❯](bold fg:color_green)";
        error_symbol = "[❯](bold fg:color_red)";
        vimcmd_symbol = "[❮](bold fg:color_green)";
        vimcmd_replace_one_symbol = "[❮](bold fg:color_purple)";
        vimcmd_replace_symbol = "[❮](bold fg:color_purple)";
        vimcmd_visual_symbol = "[❮](bold fg:color_yellow)";
      };
    };
  };

  programs.tmux = {
    enable = true;
    shortcut = "a";
    baseIndex = 1;
    mouse = true;
    terminal = "xterm-256color";
    sensibleOnTop = true;
    plugins = with pkgs; [
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
          set -g status-right-length 100
          set -g status-left-length 100
          set -g status-left ""
          set -g status-right "#{E:@catppuccin_status_application}"
          set -ag status-right "#{E:@catppuccin_status_session}"
          set -agF status-right "#{E:@catppuccin_status_cpu}"
          set -ag status-right "#{E:@catppuccin_status_uptime}"

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
      tmuxPlugins.cpu
      tmuxPlugins.yank
    ];
    extraConfig = ''
      # See: tmux/tmux#696
      set-option -ga terminal-overrides ",xterm-256color:Tc"
      # Fix shell on startup, see: tmux/tmux#4166
      set -g default-command '$SHELL'
    '';
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
