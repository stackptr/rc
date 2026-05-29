{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.karabiner;

  configJson = builtins.toJSON {
    global.show_in_menu_bar = false;
    profiles = [
      {
        complex_modifications.rules = cfg.complexModifications;
        inherit (cfg) devices;
        name = "Default profile";
        selected = true;
        virtual_hid_keyboard.keyboard_type_v2 = "ansi";
      }
    ];
  };
in {
  options.programs.karabiner = {
    enable = mkEnableOption "Karabiner-Elements";

    startOnActivation = mkEnableOption "starting Karabiner-Elements on activation";

    devices = mkOption {
      type = types.listOf types.attrs;
      default = [];
      description = "Device entries to include in the Karabiner profile.";
    };

    complexModifications = mkOption {
      type = types.listOf types.attrs;
      default = [];
      description = "Complex modification rules to include in the Karabiner profile.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.karabiner-elements];

    # Karabiner-Elements does not support being managed via defaults(1); write
    # the JSON config directly during activation instead.
    system.activationScripts.postActivation.text = let
      user = lib.escapeShellArg config.system.primaryUser;
      configFile = pkgs.writeText "karabiner.json" configJson;
    in ''
      echo "configuring karabiner-elements..." >&2
      sudo --user=${user} -- mkdir -p ~${user}/.config/karabiner
      sudo --user=${user} -- cp -f ${configFile} ~${user}/.config/karabiner/karabiner.json
    '';

    system.startOnActivation = mkIf cfg.startOnActivation {
      "karabiner_observer" = "${pkgs.karabiner-elements}/Applications/Karabiner-Elements.app/";
    };
  };
}
