{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib; let
  cfg = config.programs.cmux;

  jsonFormat = pkgs.formats.json {};

  valueToString = v:
    if isBool v
    then boolToString v
    else toString v;

  ghosttyConfigText =
    concatStringsSep "\n" (
      mapAttrsToList (k: v: "${k} = ${valueToString v}") cfg.ghostty.settings
      ++ map (idx: "palette = ${idx}=${cfg.ghostty.palette.${idx}}")
      (sort (a: b: toInt a < toInt b) (attrNames cfg.ghostty.palette))
    )
    + "\n";
in {
  options.programs.cmux = {
    enable = mkEnableOption "cmux";

    defaults = {
      enable = mkEnableOption "cmux and ghostty shared defaults";
    };

    settings = mkOption {
      inherit (jsonFormat) type;
      default = {};
      description = ''
        Configuration written to {file}`~/.config/cmux/cmux.json`.
        Keys map directly to cmux JSON config fields.
      '';
    };

    ghostty = {
      settings = mkOption {
        type = types.attrsOf (types.oneOf [types.str types.int types.float types.bool]);
        default = {};
        description = ''
          Ghostty settings written to {file}`~/.config/ghostty/config`
          as `key = value` pairs.
        '';
      };

      palette = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = ''
          Terminal color palette written as `palette = <index>=<color>` lines
          in {file}`~/.config/ghostty/config`. Keys must be numeric strings "0"–"15".
        '';
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.defaults.enable {
      programs.cmux.settings = {
        app.minimalMode = mkDefault true;
        ui.surfaceTabBar.buttons = mkDefault [
          "cmux.newTerminal"
          "cmux.splitRight"
          "cmux.splitDown"
        ];
        workspaceColors = mkDefault {
          notificationBadgeColor = null;
          indicatorStyle = "leftRail";
          selectionColor = null;
          colors = {
            Red = "#ff7b72";
            Orange = "#ffa657";
            Green = "#7ee787";
            Blue = "#79c0ff";
            Sky = "#a5d6ff";
            Purple = "#d2a8ff";
            Pink = "#ff6ac1";
            Cyan = "#9aedfe";
          };
        };
        shortcuts.bindings = mkDefault {
          openFolder = "";
          reopenPreviousSession = "";
          goToWorkspace = "cmd+o";
          commandPalette = "cmd+p";
          nextSurface = "cmd+opt+→";
          prevSurface = "cmd+opt+←";
          nextSidebarTab = "cmd+opt+↓";
          prevSidebarTab = "cmd+opt+↑";
          closeOtherTabsInPane = "";
          selectSurfaceByNumber = "cmd+1";
          selectWorkspaceByNumber = "ctrl+1";
        };
      };

      programs.cmux.ghostty = {
        settings = mapAttrs (_: mkDefault) {
          background = "#131313";
          foreground = "#dddddd";
          "cursor-color" = "#dddddd";
          "selection-background" = "#353436";
          "selection-foreground" = "#dddddd";
          "font-family" = "MesloLGSDZ Nerd Font Mono";
          "font-size" = 12;
          "window-padding-x" = 8;
          "window-padding-y" = 8;
        };
        palette = mapAttrs (_: mkDefault) {
          "0" = "#131313";
          "1" = "#ff5c57";
          "2" = "#5af78e";
          "3" = "#f3f99d";
          "4" = "#57c7ff";
          "5" = "#ff6ac1";
          "6" = "#9aedfe";
          "7" = "#caccca";
          "8" = "#686868";
          "9" = "#ff7b72";
          "10" = "#7ee787";
          "11" = "#ffa657";
          "12" = "#79c0ff";
          "13" = "#d2a8ff";
          "14" = "#a5d6ff";
          "15" = "#ffffff";
        };
      };
    })

    (mkIf cfg.enable {
      homebrew.casks = ["cmux"];

      home-manager.users.${username} = {
        xdg.configFile."cmux/cmux.json" = {
          source = jsonFormat.generate "cmux-config" ({
              "$schema" = "https://raw.githubusercontent.com/manaflow-ai/cmux/main/web/data/cmux.schema.json";
              schemaVersion = 1;
            }
            // cfg.settings);
        };

        xdg.configFile."ghostty/config" = mkIf (cfg.ghostty.settings != {} || cfg.ghostty.palette != {}) {
          text = ghosttyConfigText;
        };
      };
    })
  ];
}
