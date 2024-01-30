{pkgs, ...}: {
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

    sessionVariables =
      if pkgs.stdenv.isDarwin
      then {
        FR_DOCKERHOST = "docker.for.mac.localhost";
      }
      else {
        # See: https://www.gnupg.org/documentation/manuals/gnupg/Invoking-GPG_002dAGENT.html
        GPG_TTY = "$(tty)";
      };

    shellAliases = {
      git = "hub";
      ssh = "mosh";
    };

    syntaxHighlighting = {
      enable = true;
    };

    initExtra = ''
      incog () {
        unset HISTFILE
      }

      if command -v nix-your-shell > /dev/null; then
        nix-your-shell zsh | source /dev/stdin
      fi

      setopt hist_verify
      setopt inc_append_history

      # Pure prompt is not supported by Warp
      if [[ -n "$IN_NIX_SHELL" || -z "$WARP_IS_LOCAL_SHELL_SESSION" ]]; then
        autoload -U promptinit; promptinit
        prompt pure
      fi

      ## Wrappers for `stack`

      # Build project and specs without running tests:
      #   sbuild fancy-api
      #
      # Omit argument to build everything
      sbuild () {
        AWS_PROFILE=freckle-dev stack build "''${STACK_ARGS[@]}" "$1" --test --no-run-tests --file-watch
      }

      # Test specific matcher pattern with stack:
      #   stest project "matcher pattern"
      stest () {
        AWS_PROFILE=freckle-dev stack build "''${STACK_ARGS[@]}" --test "$1" --test-arguments="--match \"$2\"" --file-watch
      }

      # Purge package from stack to force rebuild
      spurge () {
        stack exec -- ghc-pkg unregister --force "$1"
      }
    '';
  };
}
