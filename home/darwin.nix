{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.targets.darwin.home;
in {
  options.targets.darwin.home = {
    enable = lib.mkEnableOption "Enable Darwin home files";
  };
  config = lib.mkIf cfg.enable {
    home.file."${config.home.homeDirectory}/Library/Scripts/Applications/Safari/Quit with Confirmation.applescript".text = ''
      use AppleScript version "2.4"
      use scripting additions

      tell application "Safari"
          set _window_count to count windows
          set _tab_count to 0

          repeat with _w in every window
              set _tab_count to _tab_count + (count tabs of _w)
          end repeat

          -- Make a string like "1 window containing 3 tabs."
          if _window_count is 1 then
              set _msg to _window_count & " window containing " as string
          else
              set _msg to _window_count & " windows containing " as string
          end if
          if _tab_count is 1 then
              set _msg to _msg & _tab_count & " tab." as string
          else
              set _msg to _msg & _tab_count & " tabs." as string
          end if

          display alert ¬
              "Are you sure you want to quit Safari?" message _msg ¬
              buttons {"Cancel", "Quit"} ¬
              giving up after 60
          if button returned of result is "Quit" then quit
      end tell
    '';
  };
}
