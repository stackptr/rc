{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.system.disableUpdates;
in {
  options.system.disableUpdates = mkOption {
    type = types.listOf types.str;
    default = [];
    example = literalExpression ''
      [
        "com.jordanbaird.Ice"
      ]
    '';
    description = ''
      List of domains to write defaults that attempt to disable automatic software updates and associated prompts.

      Keys are set according to [constants](https://github.com/sparkle-project/Sparkle/blob/2.x/Sparkle/SUConstants.m)
      in the Sparkle project, a popular software update framework, as well as some that have been determined
      experimentally.
    '';
  };

  config = mkIf (length cfg > 0) {
    system.defaults.CustomUserPreferences = builtins.listToAttrs (map
      (domain: {
        name = domain;
        value = {
          SUEnableAutomaticChecks = false;
          SUAutomaticallyUpdate = false;
        };
      })
      cfg);
  };
}
