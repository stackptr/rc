{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib; let
  cfg = config.programs.chromium;
in {
  options.programs.chromium = {
    enable = mkEnableOption "Chromium";

    package = mkOption {
      type = types.package;
      default = pkgs.ungoogled-chromium;
      defaultText = "pkgs.ungoogled-chromium";
      description = "The Chromium package to use.";
    };

    configDir = mkOption {
      type = types.str;
      default = "Library/Managed Preferences/Chromium";
      description = "Configuration directory for Chromium";
    };

    # TODO: This does not seem to work with ungoogled-chromium
    extensions = mkOption {
      type = types.listOf types.str;
      default = [];
      example = literalExpression ''
        [
          "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
        ]
      '';
      description = ''
        List of extensions to install.
        To find the extension ID, check its URL on the
        [Chrome Web Store](https://chrome.google.com/webstore/category/extensions).
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [cfg.package];
    home-manager.users.${username}.home.file = lib.listToAttrs (map (extId: {
        name = "${cfg.configDir}/External Extensions/${extId}.json";
        value.text = builtins.toJSON {};
      })
      cfg.extensions);
  };
}
