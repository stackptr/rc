{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;

  cfg = config.rc.gpg;
in {
  options = {
    rc.gpg = {
      enable = lib.mkEnableOption "GPG-based identity configuration";
    };
  };

  config = mkIf cfg.enable {
    programs.gpg = {
      enable = true;
      settings = {
        default-key = "413D1A0152BCB08D2E3DDACAF88C08579051AB48";
      };
    };

    programs.git.signing = {
      key = "F88C08579051AB48";
      signByDefault = true;
      format = "openpgp";
    };

    services.gpg-agent = {
      enable = true;
      enableScDaemon = true;
      enableSshSupport = true;
      enableZshIntegration = true;
      defaultCacheTtlSsh = 600;
      maxCacheTtlSsh = 3600;
      noAllowExternalCache = true;
      pinentry.package = with pkgs;
        if stdenv.isDarwin
        then pinentry_mac
        else pinentry-tty;
    };
  };
}
