{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.programs.popclip;
in {
  options.programs.popclip = {
    enable = lib.mkEnableOption (lib.mdDoc "Enable PopClip to show iOS-style contextual menu for selected text.");
    greedy = lib.mkEnableOption (lib.mdDoc "Disable PopClip's auto-updates in favor of verison from Homebrew tap");
    extensions = lib.mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["Parcel.popclipextz"];
      description = "List of extensions to use.";
    };
    items = lib.mkOption {
      type = types.listOf types.str;
      default = [];
      example = [
        "openlink"
        "search"
        "cut"
        "copy"
        "paste"
      ];
      description = "List of items to show in the context menu.";
    };
  };

  config = lib.mkIf cfg.enable {
    homebrew.casks = [
      {
        name = "popclip";
        greedy = cfg.greedy;
      }
    ];
    system.defaults.CustomUserPreferences = {
      "com.pilotmoon.popclip" = {
        SUEnableAutomaticChecks = lib.mkIf cfg.greedy false;
        CombinedItemOrder = [
          "openlink"
          "search"
          "cut"
          "copy"
          "paste"
          "revealfile"
          "lookup"
          "ext-com.pilotmoon.popclip.extension.parcel"
          "openmail"
        ];
        HasShownWelcome = true;
        NMStatusItemHideIcon = true;
        "extension#com.pilotmoon.popclip.builtin-search#template" = "https://kagi.com/search?q=***";
      };
    };
    system.activationScripts.postUserActivation.text = ''
      popclipExtPlist=~/Library/Application\ Support/PopClip/Extensions/Extensions.plist
      if test -f "$popclipExtPlist"; then
        if [[ ! `defaults read "$popclipExtPlist" "Installed Extensions"` =~ "Parcel.popclipext" ]]; then
          echo "installing popclip parcel extension..." >&2
          pkill PopClip || true # Kill process if needed; don't exit if command fails
          temp=$(mktemp -d)
          curl -s --output-dir "$temp" https://pilotmoon.com/popclip/extensions/ext/Parcel.popclipextz -O
          open "$temp/Parcel.popclipextz"
          sleep 2 # Allow extension to install before starting PopClip below
          rm -r "$temp"
        fi
      fi

      echo "starting PopClip..." >&2
      pgrep -q PopClip || open /Applications/PopClip.app/
    '';
  };
}
