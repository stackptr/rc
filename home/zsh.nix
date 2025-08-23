{pkgs, ...}: {
  programs.zsh = {
    enable = true;
    defaultKeymap = "emacs";

    history = {
      extended = true;
      ignoreSpace = true;
      save = 10000;
      size = 50000;
    };

    historySubstringSearch = {
      enable = true;
      searchUpKey = ["^[[A" "^[OA"];
      searchDownKey = ["^[[B" "^[OB"];
    };

    sessionVariables = let
      baseVars = {
        MANPAGER = "sh -c 'col -bx | bat -l man -p'";
        MANROFFOPT = "-c";
      };
      osVars =
        if pkgs.stdenv.isDarwin
        then {
          FR_DOCKERHOST = "docker.for.mac.localhost";
        }
        else {
          # See: https://www.gnupg.org/documentation/manuals/gnupg/Invoking-GPG_002dAGENT.html
          GPG_TTY = "$(tty)";
        };
    in
      baseVars // osVars;

    shellAliases = {
      cat = "bat -p";
      git = "hub";
      vim = "nvim";
    };

    syntaxHighlighting = {
      enable = true;
    };

    initContent = let
      novaCompletion = "compdef _files nova";
    in ''
      incog () {
        unset HISTFILE
      }

      if command -v nix-your-shell > /dev/null; then
        nix-your-shell zsh | source /dev/stdin
      fi

      setopt hist_verify
      setopt inc_append_history

      ## Wrappers for `stack`
      export STACK_ARGS=(--fast --pedantic)

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
    '' + novaCompletion;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
