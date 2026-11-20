{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.codexbar;
in {
  options.programs.codexbar = {
    enable = mkEnableOption "CodexBar";

    startOnActivation = mkEnableOption "starting CodexBar on activation";
  };

  # The cask rather than nixpkgs' codexbar, which trails releases and wraps the
  # GUI binary as `codexbar`; the cask links the real CLI. Provider settings
  # (the Claude source included) live in ~/.codexbar/config.json alongside
  # cookie headers, not in defaults, so they stay unmanaged.
  config = mkIf cfg.enable {
    homebrew.casks = ["codexbar"];
    system.startOnActivation = mkIf cfg.startOnActivation {
      CodexBar = "/Applications/CodexBar.app/";
    };
  };
}
