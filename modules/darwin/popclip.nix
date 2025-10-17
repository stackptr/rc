{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.popclip;
in {
  options.programs.popclip = {
    enable = mkEnableOption "PopClip";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      {
        name = "popclip";
        greedy = true;
      }
    ];
    system.defaults.CustomUserPreferences = {
      "com.pilotmoon.popclip" = {
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
    system.disableUpdates = ["com.pilotmoon.popclip"];
    system.activationScripts.popclipExtensions.text = ''
      popclipExtPlist=~/Library/Application\ Support/PopClip/Extensions/Extensions.plist
      if test -f "$popclipExtPlist"; then
        if [[ ! $(defaults read "$popclipExtPlist" "Installed Extensions") == *"Parcel.popclipext"* ]]; then
          echo "installing popclip parcel extension..." >&2
          pkill PopClip || true # Kill process if needed; don't exit if command fails
          temp=$(mktemp -d)
          curl -s --output-dir "$temp" https://pilotmoon.com/popclip/extensions/ext/Parcel.popclipextz -O
          open "$temp/Parcel.popclipextz"
          sleep 2 # Allow extension to install before starting PopClip below
          rm -r "$temp"
        fi
      fi
    '';
  };
}
