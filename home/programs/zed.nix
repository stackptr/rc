{pkgs, ...}: {
  programs.zed-editor = {
    enable = true;
    mutableUserSettings = false;
    userSettings = {
      auto_update = false;
      theme = {
        mode = "system";
        light = "Nova Light";
        dark = "Nova Dark";
      };
      icon_theme = "Zed (Default)";

      ui_font_size = 15.0;
      ui_font_family = ".SystemUIFont";
      buffer_font_size = 12.0;
      buffer_font_family = "MesloLGSDZ Nerd Font Mono";
      buffer_line_height = "comfortable";
      show_wrap_guides = true;
      use_system_path_prompts = false;
      diff_view_style = "unified";

      title_bar = {
        show_branch_icon = true;
        show_branch_name = true;
        show_project_items = true;
        show_onboarding_banner = false;
        show_user_picture = false;
        show_user_menu = true;
        show_sign_in = true;
        show_menus = false;
      };

      current_line_highlight = "all";
      gutter = {
        line_numbers = true;
        runnables = false;
        breakpoints = false;
        folds = true;
        min_line_number_digits = 3;
      };

      indent_guides = {
        enabled = true;
        line_width = 1;
        active_line_width = 1;
        coloring = "indent_aware";
        background_coloring = "disabled";
      };
      sticky_scroll = {enabled = true;};
      git = {
        inline_blame = {
          enabled = true;
          delay_ms = 0;
          min_column = 0;
          padding = 10;
          show_commit_summary = true;
        };
      };
      toolbar = {
        breadcrumbs = true;
        quick_actions = false;
        selections_menu = false;
        agent_review = false;
        code_actions = false;
      };

      max_tabs = null;

      tab_bar = {
        show = true;
        show_nav_history_buttons = false;
        show_tab_bar_buttons = false;
      };
      tabs = {
        git_status = true;
        close_position = "left";
        show_close_button = "hover";
        file_icons = true;
        show_diagnostics = "errors";
        activate_on_close = "left_neighbour";
      };
      extend_comment_on_newline = false;

      status_bar = {
        active_language_button = true;
        cursor_position_button = true;
        line_endings_button = false;
        active_encoding_button = "non_utf8";
      };

      snippet_sort_order = "inline";
      show_completions_on_input = true;
      show_completion_documentation = true;
      auto_signature_help = false;
      show_signature_help_after_edits = false;
      inline_code_actions = true;
      lsp_document_colors = "inlay";
      completion_menu_scrollbar = "system";
      colorize_brackets = true;

      diagnostics_max_severity = "all";
      diagnostics = {
        button = true;
        include_warnings = false;
        inline = {
          enabled = true;
        };
      };

      edit_predictions = {
        provider = "sweep";
        mode = "eager";
        enabled_in_text_threads = true;
      };
      show_edit_predictions = true;

      load_direnv = "shell_hook";
      double_click_in_multibuffer = "open";

      file_finder = {
        file_icons = true;
        modal_max_width = "small";
        git_status = true;
        include_ignored = "smart";
      };

      project_panel = {
        button = true;
        default_width = 240;
        dock = "left";
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
      git_panel = {
        tree_view = true;
        button = true;
        dock = "right";
        status_style = "label_color";
        fallback_branch_name = "main";
        sort_by_path = false;
        collapse_untracked_diff = false;
        scrollbar = {show = null;};
      };
      terminal = {
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
      collaboration_panel = {button = true;};
      outline_panel = {button = false;};
      notification_panel = {button = false;};
      debugger = {button = false;};

      prettier = {allowed = true;};
      languages = {
        JavaScript = {
          tab_size = 2;
          formatter = {
            external = {
              command = "prettier";
              arguments = ["--stdin-filepath" "{buffer_path}"];
            };
          };
          format_on_save = "on";
        };
        Nix = {
          language_servers = ["nil" "!nixd"];
          formatter = {
            external = {
              command = "alejandra";
              arguments = ["--quiet" "--"];
            };
          };
        };
      };
      lsp = {
        eslint = {
          settings = {
            workingDirectory = {mode = "auto";};
          };
        };
      };

      agent = {
        default_model = {
          provider = "anthropic";
          model = "claude-sonnet-4-6-latest";
          enable_thinking = false;
        };
        favorite_models = [];
        model_parameters = [];
      };

      context_servers = {
        glyph = {
          settings = {
            url = "http://glyph:8090/mcp";
          };
        };
      };

      ssh_connections = [
        {
          host = "glyph";
          username = "mu";
          args = [];
          projects = [
            {paths = ["/home/mu/Development/rc"];}
          ];
        }
      ];
    };
  };
}
