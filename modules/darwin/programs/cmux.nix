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

    settings = mkOption {
      inherit (jsonFormat) type;
      default = {};
      description = ''
        Configuration written to {file}`~/.config/cmux/cmux.json`.
        Keys map directly to cmux JSON config fields.
      '';
      example = literalExpression ''
        {
          schemaVersion = 1;
          app.minimalMode = true;
          shortcuts.bindings = {
            goToWorkspace = "cmd+o";
            commandPalette = "cmd+p";
          };
        }
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
        example = literalExpression ''
          {
            background = "#131313";
            foreground = "#dddddd";
            "cursor-color" = "#dddddd";
            "font-family" = "MesloLGSDZ Nerd Font Mono";
            "font-size" = 12;
          }
        '';
      };

      palette = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = ''
          Terminal color palette written as `palette = <index>=<color>` lines
          in {file}`~/.config/ghostty/config`. Keys must be numeric strings "0"–"15".
        '';
        example = literalExpression ''
          {
            "0" = "#131313";
            "1" = "#ff5c57";
            "15" = "#ffffff";
          }
        '';
      };
    };
  };

  config = mkIf cfg.enable {
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
  };
}
