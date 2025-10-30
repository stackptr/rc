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

    shellAliases = {
      cat = "bat -p";
      vim = "nvim";
    };

    syntaxHighlighting = {
      enable = true;
    };

    initContent = let
      novaCompletion = "compdef _files nova";
    in
      ''
        incog () {
          unset HISTFILE
        }

        if command -v nix-your-shell > /dev/null; then
          nix-your-shell zsh | source /dev/stdin
        fi

        setopt hist_verify
        setopt inc_append_history
      ''
      + novaCompletion;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
