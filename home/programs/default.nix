{pkgs, ...}: {
  imports = [
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
    };
  };
}
