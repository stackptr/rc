{
  pkgs,
  lib,
  enableGuiPackages,
  ...
}: {
  imports = [
    ./programs
    ./services.nix
  ];

  home.packages = with pkgs; let
    nodejs = pkgs.nodejs_24;
    yarn = pkgs.yarn-berry.override {inherit nodejs;};
    development = [
      colima
      docker
      hub
      jo
      nodejs
      shellcheck
      tree
      yarn
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
      git-interactive-rebase-tool
      lazydocker
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
    guiApps = [cinny-desktop];
  in
    development
    ++ nixSpecific
    ++ tuiApps
    ++ utilities
    ++ lib.optionals enableGuiPackages guiApps;
  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  home.stateVersion = "23.11";
}
