{
  pkgs,
  lib,
  hostname,
  ...
}: {
  imports = [
    ./programs
    ./services.nix
  ];

  home.packages = with pkgs; let
    development = [
      yq
    ];
    tuiApps = [
      claude-code
    ];
    utilities = [
      coreutils-full
      mosh
      neofetch
      onefetch
    ];
  in
    tuiApps
    ++ utilities
    ++ development;
  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  rc.development = lib.mkIf (hostname != "spore") {
    containers.enable = true;
    javascript.enable = true;
  };

  rc.git = {
    enable = true;
    enableInteractiveRebase = true;
  };

  rc.utilities = lib.mkMerge [
    {
      nix.enable = true;
      system.enable = true;
    }

    (lib.mkIf (hostname != "spore") {
      file.enable = true;
      media.enable = true;
    })
  ];

  home.stateVersion = "23.11";
}
