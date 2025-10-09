{
  self,
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./disable-updates.nix
    ./fastscripts.nix
    ./fonts.nix
    ./homebrew.nix
    ./popclip.nix
    ./scroll-reverser.nix
    ./security.nix
    ./start-on-activation.nix
    ./startup-apps.nix
    ./system-defaults.nix
  ];

  programs.fastscripts = {
    enable = true;
    userScripts = {
      SafariQuitWithConfirmation = {
        source = pkgs.writeText "safari-quit-with-confirmation.applescript" (builtins.readFile ./fastscripts/safari-quit-with-confirmation.applescript);
        target = "Applications/Safari/Quit With Confirmation.applescript";
      };
    };
    plistFile = pkgs.writeText "fastscripts-keybindings.plist" (builtins.readFile ./fastscripts/keybindings.plist);
  };

  # TODO: Ideally this would be in a Darwin-specific home-manager module
  programs.popclip = {
    enable = true;
  };

  programs.scroll-reverser = {
    enable = true;
  };

  system.configurationRevision = self.rev or self.dirtyRev or null;

  # TODO: Keyboard shortcuts, see nix-darwin/nix-darwin#699
  # system.keyboard.shortcuts = let
  #   cmdOptLeft = {
  #     mods = {
  #       option = true;
  #       command = true;
  #     };
  #     key = "left";
  #   };
  #   cmdOptRight = {
  #     mods = {
  #       option = true;
  #       command = true;
  #     };
  #     key = "right";
  #   };
  # in {
  #   enable = true;
  #   appShortcuts = {
  #     "Preview.app" = {
  #       "Show Previous Tab" = cmdOptLeft;
  #       "Show Next Tab" = cmdOptRight
  #     };
  #     "Finder.app" = {
  #       "Show Previous Tab" = cmdOptLeft;
  #       "Show Next Tab" = cmdOptRight
  #     };
  #     "Prompt.app" = {
  #       "Show Previous Tab" = cmdOptLeft;
  #       "Show Next Tab" = cmdOptRight
  #     };
  #     "Mail.app" = {
  #       "Archive" = {
  #         key = "right";
  #       };
  #     };
  #     "Nova.app" = {
  #       "Show Previous Tab" = cmdOptLeft;
  #       "Show Next Tab" = cmdOptRight
  #     };
  #   };
  # };

  # Auto upgrade nix package and the daemon service.
  nix.enable = true;
  nix.package = pkgs.nix;
}
