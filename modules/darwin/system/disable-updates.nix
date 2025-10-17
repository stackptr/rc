{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.system.disableUpdates;

  updateOptions = {config, ...}: {
    options = {
      domain = mkOption {
        type = types.str;
        description = "Domain of application for which updates will be disabled";
      };

      keys = mkOption {
        type = types.listOf types.str;
        description = "Keys used for software update";
      };
    };
  };

  # Defaults from: https://github.com/sparkle-project/Sparkle/blob/2.x/Sparkle/SUConstants.m
  defaultKeys = ["SUEnableAutomaticChecks" "SUAutomaticallyUpdate"];
in {
  options.system.disableUpdates = mkOption {
    type = with types;
      listOf (coercedTo str (domain: {
        inherit domain;
        keys = defaultKeys;
      }) (submodule updateOptions));
    default = [];
    example = literalExpression ''
      [
        "com.example.App"
        {
          domain = "com.enterprise.App";
          keys = ["CustomSoftwareUpdateFramework"]
        }
      ]
    '';
    description = let
      quoteStr = k: "\"${k}\"";
      defaultKeysStr = builtins.concatStringsSep " " (map quoteStr defaultKeys);
    in ''
      List of domains and associated keys to write defaults that attempt to disable
      automatic software updates and associated prompts.

      Domains defined as strings, e.g. "com.example.App", are shorthand for default keys:

      `{ domain = "com.example.App"; keys = [${defaultKeysStr}]; }`

      Default keys are from the Sparkle project, a popular software update framework.
    '';
  };

  config = mkIf (length cfg > 0) {
    system.defaults.CustomUserPreferences = let
      mkDisabledValues = keys:
        builtins.listToAttrs (map (key: {
            name = key;
            value = false;
          })
          keys);
    in
      builtins.listToAttrs (map
        (
          e: {
            name = e.domain;
            value = mkDisabledValues e.keys;
          }
        )
        cfg);
  };
}
