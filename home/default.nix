{pkgs, ...}: {
  imports = [
    ./zsh.nix
  ];

  home.packages = let
    nodejs = pkgs.nodejs_20;
    yarn = pkgs.yarn.override {inherit nodejs;};
  in
    with pkgs;
      [
        alejandra
        coreutils-full
        fd
        ffmpeg_6
        git-interactive-rebase-tool
        hub
        jo
        mediainfo
        mosh
        neofetch
        neovim
        nodejs
        nix-your-shell
        shellcheck
        sox
        statix
        tree
        yarn
        yq
      ]
      ++ lib.optionals stdenv.isDarwin [
        m-cli
      ];

  programs.awscli = {
    enable = true;
    settings = import ./aws.nix;
  };

  programs.btop.enable = true;

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.git = {
    enable = true;
    userName = "✿ corey";
    userEmail = "corey@x64.co";
    signing = {
      key = "F88C08579051AB48";
      signByDefault = true;
    };
    extraConfig = {
      sequence.editor = "interactive-rebase-tool";
    };
  };

  programs.gpg = {
    enable = true;
  };

  programs.htop.enable = true;

  programs.jq.enable = true;

  services.gpg-agent = {
    # TODO: nix-community/home-manager#2964
    enable =
      if pkgs.stdenv.isDarwin
      then false
      else true;
    enableZshIntegration = true;
    pinentryFlavor = "tty";
    extraConfig = ''
      allow-loopback-pinentry
    '';
  };

  programs.nushell.enable = true;

  programs.ripgrep.enable = true;

  programs.yt-dlp.enable = true;

  home.stateVersion = "23.11";
}
