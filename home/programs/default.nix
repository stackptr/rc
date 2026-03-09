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
