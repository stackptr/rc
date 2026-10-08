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

    # The daemon signals before removing its socket, so clear the flag here
    # rather than re-checking the socket when upstream redraws the prompt
    if (( $+functions[TRAPUSR1] )); then
      functions[_direnv_instant_loading_orig_TRAPUSR1]=$functions[TRAPUSR1]
      TRAPUSR1() {
        unset DIRENV_INSTANT_LOADING
        _direnv_instant_loading_orig_TRAPUSR1 "$@"
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
          "${config.home.homeDirectory}/Development/heave"
          "${config.home.homeDirectory}/Development/rc"
          "${config.home.homeDirectory}/Development/conductor/workspaces/heave"
          "${config.home.homeDirectory}/Development/conductor/workspaces/rc"
        ];
      };
    };
  };
}
