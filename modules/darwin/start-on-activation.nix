{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.system.startOnActivation;
  openIfNotRunning = proc: path: "pgrep -q ${proc} || open ${path}";
in {
  options.system.startOnActivation = mkOption {
    type = types.attrsOf types.str;
    default = {};
    example = literalExpression ''
      {
        "Ice" = "$${pkgs.ice-bar}/Applications/Ice.app/";
        "Notes" = "/System/Applications/Notes.app";
      }
    '';
    description = ''
      Applications to start when the nix-darwin configuration is activated.

      The name of the attribute corresponds to the process to check prior to opening
      the application, the path of which is given as the attribute value.
    '';
  };

  config = mkIf (length (attrNames cfg) > 0) {
    system.activationScripts.postActivation.text =
      ''
        echo "starting utilties..." >&2
      ''
      + builtins.concatStringsSep "\n" (mapAttrsToList openIfNotRunning cfg);
  };
}
