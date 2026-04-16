{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkOption;

  cfg = config.rc.gpg;
in {
  options = {
    rc.gpg = {
      enable = lib.mkEnableOption "GPG-based identity configuration";
    };
  };

  config = mkIf cfg.enable {
    services.gpg-agent = {
      enable = true;
      enableScDaemon = true;
      enableSshSupport = true;
      enableZshIntegration = true;
      defaultCacheTtlSsh = 600;
      maxCacheTtlSsh = 3600;
      pinentry.package = with pkgs;
        if stdenv.isDarwin
        then pinentry_mac
        else pinentry-tty;
    };
  };
}
