{
  pkgs,
  lib,
  config,
  options,
  ...
}: {
  imports = [
    ./aichat.nix
    ./starship.nix
    ./tmux.nix
    ./zsh.nix
  ];

  # Replaces direnv's shell hook; runs direnv in a background daemon so slow
  # devShell loads don't block the prompt
  programs.direnv-instant = {
    enable = true;
    # Upstream falls back to blocking direnv outside a multiplexer
    # (Mic92/direnv-instant#103); patch that out so loads are always async
    package = options.programs.direnv-instant.package.default.overrideAttrs (old: {
      patches = (old.patches or []) ++ [./patches/direnv-instant-async-without-mux.patch];
      # These assert the blocking fallback that the patch removes
      checkFlags =
        (old.checkFlags or [])
        ++ map (t: "--skip=${t}") [
          "no_tmux_runs_direnv_synchronously"
          "ctrl_c_cancels_direnv_in_non_mux_mode"
          "fish_runs_direnv_synchronously"
        ];
    });
  };

  # Exports DIRENV_INSTANT_LOADING while a direnv-instant load is in flight, for
  # the starship indicator. Ordered after the direnv-instant hook so this precmd
  # runs after `direnv-instant start` and the TRAPUSR1 wrapper sees upstream's.
  programs.zsh.initContent = lib.mkOrder 1500 ''
    zmodload zsh/zselect

    _direnv_instant_loading_precmd() {
      local sock=''${__DIRENV_INSTANT_ENV_FILE:h}/daemon.sock
      if [[ -z $__DIRENV_INSTANT_CURRENT_DIR || ! -S $sock ]]; then
        unset DIRENV_INSTANT_LOADING
        return
      fi
      # Already flagged by an earlier prompt; don't add latency again
      [[ -n $DIRENV_INSTANT_LOADING ]] && return
      # The daemon also runs briefly on every prompt for no-op exports; only
      # flag loads that outlive a short grace period (10 x 10ms)
      local i
      for i in {1..10}; do
        zselect -t 1
        [[ -S $sock ]] || return
      done
      export DIRENV_INSTANT_LOADING=1
    }
    add-zsh-hook precmd _direnv_instant_loading_precmd

    # In this dir, drop a finished load's output unless it reports a problem
    # (the whole output is kept so multi-line nix traces stay intact; nix's
    # dirty-tree warning is ignored)
    typeset -g _direnv_instant_quiet_dir=${config.home.homeDirectory}/Development/rc

    # Prints a finished load's output; returns non-zero if nothing was printed
    _direnv_instant_replay() {
      local f=$__DIRENV_INSTANT_STDERR_FILE
      [[ -n $f && -s $f ]] || return 1
      local out=$(<$f)
      command rm -f $f
      if [[ $__DIRENV_INSTANT_CURRENT_DIR == $_direnv_instant_quiet_dir ]] &&
        ! print -r -- $out | command grep -viE 'warning: Git tree .* is dirty' |
        command grep -qiE 'error|fail|warn|denied|blocked'; then
        return 1
      fi
      # `zle -I` moves the output above the line being edited; zle redraws the
      # prompt and buffer when the trap returns
      zle && zle -I
      print -r -- $out
    }

    # Replaces upstream's handler, which prints at the cursor and then resets
    # the prompt, drawing over the last lines on a multi-line prompt. Also
    # clears the loading flag here, since the daemon signals before removing
    # its socket.
    if (( $+functions[TRAPUSR1] )); then
      TRAPUSR1() {
        unset DIRENV_INSTANT_LOADING
        local printed=0
        _direnv_instant_replay && printed=1
        local env_file=$__DIRENV_INSTANT_ENV_FILE
        [[ -n $env_file && -f $env_file ]] && eval "$(<$env_file)"
        (( $+functions[__direnv_instant_orig_TRAPUSR1] )) && __direnv_instant_orig_TRAPUSR1 "$@"
        # Nothing printed means no `zle -I` redraw is coming
        if (( ! printed )) && zle; then
          zle .reset-prompt
          zle -R
        fi
        return 0
      }
    fi
  '';

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config = {
      global = {
        strict_env = true;
        hide_env_diff = true;
      };
      whitelist = {
        prefix = [
          "${config.home.homeDirectory}/Development/rc"
        ];
      };
    };
  };
}
