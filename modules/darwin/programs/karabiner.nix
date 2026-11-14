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

    enableDefaults = mkEnableOption "default MX Master 4 M device and mission-control/space-switching complex modifications";

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

  config = mkMerge [
    (mkIf cfg.enableDefaults {
      programs.karabiner.devices = mkDefault [
        # Logitech MX Master 4 M
        {
          identifiers = {
            is_pointing_device = true;
            product_id = 45122;
            vendor_id = 1133;
          };
          ignore = false;
        }
      ];
      programs.karabiner.complexModifications = mkDefault [
        {
          description = "Mission control";
          manipulators = [
            {
              type = "basic";
              from.pointing_button = "button7";
              to = [{key_code = "mission_control";}];
            }
          ];
        }
        {
          description = "Thumb button → Right space";
          manipulators = [
            {
              type = "basic";
              from.pointing_button = "button4";
              to = [
                {
                  key_code = "right_arrow";
                  modifiers = ["control"];
                }
              ];
            }
          ];
        }
        {
          description = "Thumb button → Left space";
          manipulators = [
            {
              type = "basic";
              from.pointing_button = "button5";
              to = [
                {
                  key_code = "left_arrow";
                  modifiers = ["control"];
                }
              ];
            }
          ];
        }
      ];
    })
    (mkIf cfg.enable {
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
    })
  ];
}
