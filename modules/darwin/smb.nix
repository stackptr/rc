{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.rc.darwin.smb-mount;
  user = lib.escapeShellArg config.system.primaryUser;
  serviceLabel = "com.rc.smb-mount";
in {
  options.rc.darwin.smb-mount = {
    enable = mkEnableOption "SMB mounting";

    smbPath = mkOption {
      type = types.nullOr types.str;
      description = ''
        Path to Samba share to mount.
      '';
    };
  };

  config = mkIf cfg.enable {
    launchd.agents."${serviceLabel}" = {
      script = ''
        [ -d "/Volumes/Media" ] || osascript -e 'mount volume "${cfg.smbPath}"'
      '';
      serviceConfig = {
        Label = serviceLabel;
        RunAtLoad = true;
        KeepAlive = true;
        StartInterval = 60;

        StandardOutPath = "/Users/corey/Library/${serviceLabel}/launchd.stdout.log";
        StandardErrorPath = "/Users/corey/Library/${serviceLabel}/launchd.stderr.log";

        UserName = user;
      };
    };
  };
}
