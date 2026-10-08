{
  pkgs,
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
