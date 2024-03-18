{pkgs, ...}: {
  imports = [
    ./aws.nix
    ./zsh.nix
  ];

  home.packages = let
    nodejs = pkgs.nodejs_20;
    yarn = pkgs.yarn.override {inherit nodejs;};
  in
    with pkgs;
      [
        # Apps
        mosh
        neofetch
        onefetch

        # Audio/video
        ffmpeg_6
        mediainfo
        sox

        # Development
        colima
        coreutils-full
        docker
        fd
        git-interactive-rebase-tool
        hub
        jo
        nodejs
        shellcheck
        tree
        yarn
        yq

        # Nix
        alejandra
        comma
        manix
        nix-du
        nix-tree
        nix-your-shell
        statix
      ]
      ++ lib.optionals stdenv.isDarwin [
        m-cli
      ];

  programs.bat = {
    enable = true;
    config = {
      theme = "Sublime Snazzy";
    };
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
      pull.rebase = true;
      push.autosetupremote = true;
      init.defaultBranch = "main";
      merge.conflictstyle = "zdiff3";
      rerere.enabled = true;
    };
  };

  programs.gpg = {
    enable = true;
  };

  programs.htop.enable = true;

  programs.jq.enable = true;

  programs.lsd = {
    enable = true;
    enableAliases = true;
    settings = {
      icons = {
        # TODO: "fancy" theme requires patched font with icons
        # https://github.com/lsd-rs/lsd#icons-not-showing-up
        theme = "unicode";
      };
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  programs.nushell.enable = true;

  programs.ripgrep.enable = true;

  programs.yt-dlp.enable = true;

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

  home.stateVersion = "23.11";
}
