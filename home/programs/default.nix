{
  pkgs,
  enableGuiPackages,
  ...
}: {
  imports = [
    ./starship.nix
    ./tmux.nix
    ./zsh.nix
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
    signing = {
      key = "F88C08579051AB48";
      signByDefault = true;
    };
    settings = {
      user = {
        name = "✿ corey";
        email = "corey@x64.co";
      };
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
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = let
        defaultConfig = {
          forwardAgent = false;
          addKeysToAgent = "no";
          compression = false;
          serverAliveInterval = 0;
          serverAliveCountMax = 3;
          hashKnownHosts = false;
          userKnownHostsFile = "~/.ssh/known_hosts";
          controlMaster = "no";
          controlPath = "~/.ssh/master-%r@%n:%p";
          controlPersist = "no";
        };
      in
        defaultConfig
        // {
          addKeysToAgent = "yes";
        };
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

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.yt-dlp.enable = true;
}
