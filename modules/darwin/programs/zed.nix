{
  config,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:
with lib; let
  cfg = config.programs.zed;

  jsonFormat = pkgs.formats.json {};
in {
  options.programs.zed = {
    enable = mkEnableOption "Zed editor";

    enableDefaults = mkEnableOption "Zed opinionated defaults";

    settings = mkOption {
      inherit (jsonFormat) type;
      default = {};
      description = ''
        Configuration written to {file}`~/.config/zed/settings.json`.
        Keys map directly to Zed JSON config fields.
      '';
    };

    themes = mkOption {
      type = types.attrsOf types.path;
      default = {};
      description = ''
        Extra theme files linked into {file}`~/.config/zed/themes/`.
        Attribute name is the filename; value is the source path.
      '';
    };
  };

  config = mkMerge [
    (mkIf cfg.enableDefaults {
      programs.zed.themes = {
        "zed-nova-theme.json" = mkDefault (inputs.zed-nova-theme + "/theme.json");
      };

      programs.zed.settings = {
        auto_update = mkDefault false;
        theme = mkDefault {
          mode = "system";
          light = "Nova Light";
          dark = "Nova Dark";
        };
        icon_theme = mkDefault {
          mode = "light";
          light = "Zed (Default)";
          dark = "Zed (Default)";
        };

        ui_font_size = mkDefault 15.0;
        ui_font_family = mkDefault ".SystemUIFont";
        buffer_font_size = mkDefault 12.0;
        buffer_font_family = mkDefault "MesloLGSDZ Nerd Font Mono";
        buffer_line_height = mkDefault "comfortable";
        show_wrap_guides = mkDefault true;
        use_system_path_prompts = mkDefault false;
        diff_view_style = mkDefault "unified";

        title_bar = mkDefault {
          show_branch_icon = true;
          show_branch_name = true;
          show_project_items = true;
          show_onboarding_banner = false;
          show_user_picture = false;
          show_user_menu = true;
          show_sign_in = true;
          show_menus = false;
        };

        current_line_highlight = mkDefault "all";
        gutter = mkDefault {
          line_numbers = true;
          runnables = false;
          breakpoints = false;
          folds = true;
          min_line_number_digits = 3;
        };

        indent_guides = mkDefault {
          enabled = true;
          line_width = 1;
          active_line_width = 1;
          coloring = "indent_aware";
          background_coloring = "disabled";
        };
        sticky_scroll = mkDefault {enabled = true;};
        git = mkDefault {
          inline_blame = {
            enabled = true;
            delay_ms = 0;
            min_column = 0;
            padding = 10;
            show_commit_summary = true;
          };
        };
        toolbar = mkDefault {
          breadcrumbs = true;
          quick_actions = false;
          selections_menu = false;
          agent_review = false;
          code_actions = false;
        };

        max_tabs = mkDefault null;

        tab_bar = mkDefault {
          show = true;
          show_nav_history_buttons = false;
          show_tab_bar_buttons = false;
        };
        tabs = mkDefault {
          git_status = true;
          close_position = "left";
          show_close_button = "hover";
          file_icons = true;
          show_diagnostics = "errors";
          activate_on_close = "left_neighbour";
        };
        extend_comment_on_newline = mkDefault false;

        status_bar = mkDefault {
          active_language_button = true;
          cursor_position_button = true;
          line_endings_button = false;
          active_encoding_button = "non_utf8";
        };

        snippet_sort_order = mkDefault "inline";
        show_completions_on_input = mkDefault true;
        show_completion_documentation = mkDefault true;
        auto_signature_help = mkDefault false;
        show_signature_help_after_edits = mkDefault false;
        inline_code_actions = mkDefault true;
        lsp_document_colors = mkDefault "inlay";
        completion_menu_scrollbar = mkDefault "system";
        colorize_brackets = mkDefault true;

        diagnostics_max_severity = mkDefault "all";
        diagnostics = mkDefault {
          button = true;
          include_warnings = false;
          inline = {enabled = true;};
        };

        edit_predictions = mkDefault {
          provider = "copilot";
          mode = "eager";
          enabled_in_text_threads = true;
        };
        show_edit_predictions = mkDefault true;

        load_direnv = mkDefault "shell_hook";
        double_click_in_multibuffer = mkDefault "open";

        file_finder = mkDefault {
          file_icons = true;
          modal_max_width = "small";
          git_status = true;
          include_ignored = "smart";
        };

        project_panel = mkDefault {
          button = true;
          default_width = 240;
          dock = "right";
          entry_spacing = "standard";
          file_icons = true;
          folder_icons = true;
          git_status = true;
          indent_size = 16;
          auto_reveal_entries = true;
          auto_fold_dirs = true;
          bold_folder_labels = false;
          sticky_scroll = true;
          drag_and_drop = true;
          scrollbar = {show = null;};
          show_diagnostics = "errors";
          indent_guides = {show = "always";};
          sort_mode = "directories_first";
          hide_root = false;
          hide_hidden = false;
        };
        git_panel = mkDefault {
          tree_view = true;
          button = true;
          dock = "right";
          status_style = "label_color";
          fallback_branch_name = "main";
          sort_by_path = false;
          collapse_untracked_diff = false;
          scrollbar = {show = null;};
        };
        terminal = mkDefault {
          toolbar = {breadcrumbs = false;};
          dock = "bottom";
          button = true;
          blinking = "terminal_controlled";
          cursor_shape = "block";
          env = {};
          scrollbar = {show = null;};
          font_family = "MesloLGSDZ Nerd Font Mono";
          max_scroll_history_lines = 10000;
        };
        collaboration_panel = mkDefault {
          dock = "right";
          button = true;
        };
        outline_panel = mkDefault {
          dock = "right";
          button = false;
        };
        notification_panel = mkDefault {button = false;};
        debugger = mkDefault {button = false;};

        prettier = mkDefault {allowed = true;};
        languages = mkDefault {
          "Plain Text" = {show_edit_predictions = false;};
          "JavaScript" = {
            tab_size = 2;
            formatter = {
              external = {
                command = "prettier";
                arguments = ["--stdin-filepath" "{buffer_path}"];
              };
            };
            format_on_save = "on";
          };
          "Nix" = {
            language_servers = ["nil" "!nixd"];
            formatter = {
              external = {
                command = "alejandra";
                arguments = ["--quiet" "--"];
              };
            };
          };
        };
        lsp = mkDefault {
          eslint = {
            settings = {
              workingDirectory = {mode = "auto";};
            };
          };
          nil = {
            settings = {
              nil = {
                nix = {
                  flake = {
                    autoArchive = true;
                  };
                };
              };
            };
          };
        };

        agent_servers = mkDefault {
          "claude-acp" = {type = "registry";};
        };

        agent = mkDefault {
          dock = "left";
          enable_feedback = false;
          default_model = {
            provider = "anthropic";
            model = "claude-sonnet-4-6-1m-context-thinking-latest";
            enable_thinking = true;
          };
          favorite_models = [];
          model_parameters = [];
          commit_message_model = {
            provider = "anthropic";
            model = "claude-sonnet-4-6-latest";
          };
        };
      };
    })

    (mkIf cfg.enable {
      homebrew.casks = ["zed"];

      home-manager.users.${username} = {
        xdg.configFile =
          {
            "zed/settings.json".source = jsonFormat.generate "zed-settings" cfg.settings;
          }
          // mapAttrs' (name: src:
            nameValuePair "zed/themes/${name}" {source = src;})
          cfg.themes;
      };
    })
  ];
}
