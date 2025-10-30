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
    nixSpecific = [
      comma
      manix
      nix-du
      nix-tree
      nix-your-shell
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
    nixSpecific
    ++ tuiApps
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
      system.enable = true;
    }

    (lib.mkIf (hostname != "spore") {
      file.enable = true;
      media.enable = true;
    })
  ];

  home.stateVersion = "23.11";
}
