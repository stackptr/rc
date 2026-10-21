{
  pkgs,
  lib,
  ...
}: {
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

    sessionVariables = {
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      MANROFFOPT = "-c";
    };

    syntaxHighlighting = {
      enable = true;
    };

    # direnv-instant's hook evals its cached export (an absolute `export PATH=...`)
    # on every prompt, which clobbers what `nix shell` / `nix-shell -p` prepended.
    # A shell that inherits __DIRENV_INSTANT_CURRENT_DIR is nested inside a loaded
    # environment already, so it doesn't need the cache. Runs in .zshenv, before
    # the hook's first prompt.
    envExtra = ''
      [[ -n $__DIRENV_INSTANT_CURRENT_DIR ]] && typeset -g DIRENV_INSTANT_USE_CACHE=0
    '';

    initContent = ''
      incog () {
        unset HISTFILE
      }

      # Pin a prompt until prompt_auto; otherwise _prompt_auto_width picks one
      # by terminal width before every prompt.
      prompt_minimal () {
        typeset -g _prompt_mode=minimal
      }

      prompt_full () {
        typeset -g _prompt_mode=full
      }

      prompt_auto () {
        unset _prompt_mode
      }

      _prompt_auto_width () {
        if [[ $_prompt_mode == minimal || ( -z $_prompt_mode && ( "$TERM" == "linux" || $COLUMNS -lt 100 ) ) ]]; then
          export STARSHIP_CONFIG=''${XDG_CONFIG_HOME:-$HOME/.config}/starship-minimal.toml
        else
          unset STARSHIP_CONFIG
        fi
      }
      precmd_functions+=(_prompt_auto_width)

      if command -v nix-your-shell > /dev/null; then
        nix-your-shell zsh | source /dev/stdin
      fi

      setopt hist_verify
      setopt inc_append_history
    '';
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
