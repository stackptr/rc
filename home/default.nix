{ pkgs, ... }: {
  programs.home-manager.enable = true;
  home.packages = [
    pkgs.htop
    pkgs.ripgrep
    pkgs.nix-your-shell
  ];

  programs.zsh = {
    enable = true;

    history = {
      extended = true;
      ignoreSpace = true;
      save = 10000;
      size = 50000;
    };

    historySubstringSearch = {
      enable = true;
      searchUpKey = "^[[A";
      searchDownKey = "^[[B";
    };

    plugins = [
      {
        name = "pure-prompt";
        src = pkgs.fetchFromGitHub {
          owner = "sindresorhus";
          repo = "pure";
          rev = "v1.22.0";
          sha256 = "sha256-TR4CyBZ+KoZRs9XDmWE5lJuUXXU1J8E2Z63nt+FS+5w=";
        };
      }
    ];

    sessionVariables = {
    };

    syntaxHighlighting = {
      enable = true;
    };
    
    initExtra = ''
      if command -v nix-your-shell > /dev/null; then
        nix-your-shell zsh | source /dev/stdin
      fi

      # Pure prompt is not supported by Warp
      if [[ -n "$IN_NIX_SHELL" || -z "$WARP_IS_LOCAL_SHELL_SESSION" ]]; then
        autoload -U promptinit; promptinit
        prompt pure
      fi
    '';
  };

  home.stateVersion = "23.11";
}
