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
      hub
      shellcheck
      tree
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
      dua
      git-interactive-rebase-tool
    ];
    utilities = [
      coreutils-full
      fd
      ffmpeg_6
      mediainfo
      mktorrent
      mosh
      neofetch
      onefetch
      sox
      unzip
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

  home.stateVersion = "23.11";
}
