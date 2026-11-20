{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib; let
  cfg = config.programs.t3-code;

  jsonFormat = pkgs.formats.json {};

  app = "/Applications/T3 Code (Beta).app";
  policyPath = "/Library/Application Support/T3Code/policy.json";

  # Unlocked settings only replace T3's built-in defaults, so a value set in
  # the UI (stored in ~/.t3/userdata/settings.json) still wins.
  policy = jsonFormat.generate "t3code-policy.json" {
    schemaVersion = 1;
    organization = "rc";
    supportUrl = "https://github.com/stackptr/rc/blob/main/modules/darwin/programs/t3-code.nix";
    settings =
      mapAttrs (_: value: {
        inherit value;
        locked = false;
      })
      cfg.settings;
  };
in {
  options.programs.t3-code = {
    enable = mkEnableOption "T3 Code";

    enableDefaults = mkEnableOption "shared T3 Code defaults";

    settings = mkOption {
      type = types.attrsOf jsonFormat.type;
      default = {};
      example = literalExpression ''
        {
          promptSuggestionsEnabled = true;
          "storageCleanup.logsAfterDays" = 14;
        }
      '';
      description = ''
        Server settings T3 Code starts from, keyed by their dot path in its
        `ServerSettings`. They're written to the machine's managed policy as
        unlocked defaults: a value set in the UI still takes precedence. At
        activation the app's own CLI checks the policy, and a policy it
        rejects is left uninstalled, since T3 Code won't start with one.
      '';
    };
  };

  config = mkMerge [
    (mkIf cfg.enableDefaults {
      programs.t3-code = {
        settings = {
          idleCompaction = mkDefault "beforeCacheExpires";
          promptSuggestionsEnabled = mkDefault true;
          sidebarAutoSettleAfterDays = mkDefault null;
          sidebarAutoSettleOnMerge = mkDefault false;
          snoozePresets = mkDefault [
            {
              kind = "after";
              minutes = 60;
            }
            {
              kind = "after";
              minutes = 180;
            }
            {
              kind = "at";
              day = "today";
              time = "18:00";
            }
            {
              kind = "at";
              day = "tomorrow";
              time = "09:00";
            }
            {
              kind = "at";
              day = "monday";
              time = "09:00";
            }
            {
              kind = "at";
              day = "tomorrow";
              time = "11:00";
            }
          ];
          # The model that names the branch runs in the repository, so it sees
          # the repo's CLAUDE.md. T3 adds nothing to a custom-mode name.
          branchNamingMode = mkDefault "custom";
          branchNameInstructions = mkDefault "If this repository's instructions (CLAUDE.md or AGENTS.md) define a branch naming convention, follow it. Otherwise name the branch type-short-slug: type is feat, fix, chore or refactor, and the slug is 2 to 4 lowercase words joined by hyphens, e.g. fix-gc-options.";
        };
      };
    })

    (mkIf cfg.enable {
      homebrew.casks = ["t3-code"];

      system.activationScripts.postActivation.text = ''
        echo "setting up T3 Code policy..." >&2
        ${
          if cfg.settings == {}
          then ''rm -f "${policyPath}"''
          else ''
            # Checked by the app's bundled CLI, run as its ~/.t3/bin/t3 shim
            # runs it, so the check matches the installed version
            t3app="${app}/Contents/MacOS/T3 Code (Beta)"
            t3home="$(mktemp -d)"
            if [ -x "$t3app" ] \
              && ! HOME="$t3home" T3CODE_HOME="$t3home" ELECTRON_RUN_AS_NODE=1 "$t3app" \
                "${app}/Contents/Resources/app.asar/apps/server/dist/bin.mjs" policy check ${policy} > /dev/null; then
              echo "warning: T3 Code rejects ${policy}; leaving ${policyPath} as it was" >&2
            else
              mkdir -p "${dirOf policyPath}"
              install -m 0644 -o root -g wheel ${policy} "${policyPath}"
            fi
            rm -rf "$t3home"
          ''
        }
      '';

      # The app writes this shim on first launch; T3 suggests `t3` commands
      # only when the one on PATH is this shim.
      home-manager.users.${username}.home.sessionPath = ["$HOME/.t3/bin"];
    })
  ];
}
