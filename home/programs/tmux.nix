{
  pkgs,
  lib,
  showBatteryStatus,
  ...
}: let
  tmux-nerd-font-window-name = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-nerd-font-window-name";
    rtpFilePath = "tmux-nerd-font-window-name.tmux";
    version = "unstable-2025-05-27";
    src = pkgs.fetchFromGitHub {
      owner = "joshmedeski";
      repo = "tmux-nerd-font-window-name";
      rev = "4c9e7a51387d0cead1465a3628244beb790a3c95";
      hash = "sha256-UcfEsq7BqJMeYXtGDNMoi/E+iEnEe9iM2KVoi7ektOE=";
    };
  };
in {
  programs.tmux = {
    enable = true;
    # tmux-nerd-font-window-name requires yq
    package = pkgs.tmux.overrideAttrs (oldAttrs: {
      nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [pkgs.makeWrapper];
      postInstall = ''
        ${oldAttrs.postInstall or ""}

        wrapProgram $out/bin/tmux \
          --prefix PATH : "${lib.makeBinPath [pkgs.yq]}"
      '';
    });
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
        tmux-nerd-font-window-name
        {
          plugin = tmuxPlugins.catppuccin;
          extraConfig = ''
            set -g @catppuccin_flavor "mocha"
            set -g @catppuccin_status_connect_separator "no"
            set -g @catppuccin_status_left_separator  " "
            set -g @catppuccin_status_right_separator " "

            set -g @catppuccin_window_text " #W"
            set -g @catppuccin_window_current_text " #W"

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
            set -g status-left "#{E:@catppuccin_status_session}"
            set -gF status-right "#{E:@catppuccin_status_cpu}"
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
      # See: https://yazi-rs.github.io/docs/image-preview/#tmux
      set -g allow-passthrough on
      set -ga update-environment TERM
      set -ga update-environment TERM_PROGRAM
    '';
  };
}
