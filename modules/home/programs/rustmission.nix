{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkOption;

  cfg = config.programs.rustmission;

  tomlFormat = pkgs.formats.toml {};
in {
  options = {
    programs.rustmission = {
      enable = lib.mkEnableOption "rustmission";

      package = lib.mkPackageOption pkgs "rustmission" {};

      settings = mkOption {
        inherit (tomlFormat) type;
        default = {};
        example = lib.literalExpression ''
          {
            general = {
              accent_color = "LightMagenta";
              beginner_mode = true;
            };
            connection = {
              url = "http://CHANGE_ME:9091/transmission/rpc";
            };
          }
        '';
        description = ''
          Configuration written to
          {file}`$XDG_CONFIG_HOME/rustmission/config.toml`.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    warnings = lib.optional (cfg.settings.connection.url == null) ''
      You have enabled `rustmission` without setting a connection url.
    '';

    home.packages = [cfg.package];

    xdg.configFile."rustmission/config.toml" = mkIf (cfg.settings != {}) {
      source = tomlFormat.generate "rustmission-config" cfg.settings;
    };
  };
}
