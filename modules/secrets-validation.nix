# Secrets validation module
{
  config,
  lib,
  hostname,
  ...
}: let
  validation = import ../lib/validation.nix {inherit lib;};
in {
  # Add runtime validation for secrets configuration
  config = {
    assertions = [
      {
        assertion = validation.validateSecrets {
          secrets = config.age.secrets or null;
          inherit hostname;
        };
        message = "Secrets validation failed for host ${hostname}";
      }
    ];
  };
}
