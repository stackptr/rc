{
  pkgs,
  config,
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
  programs.direnv-instant.enable = true;

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
