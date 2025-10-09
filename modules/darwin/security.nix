{
  config,
  pkgs,
  lib,
  ...
}: {
  security.pam.services.sudo_local = {
    reattach = true;
    touchIdAuth = true;
  };

  system.disableUpdates = [
    "at.eggerapps.Postico"
    "com.colliderli.iina"
    "com.daisydiskapp.DaisyDiskStandAlone"
    "com.lukilabs.lukiapp" # Craft
    "com.panic.Nova"
    "com.red-sweater.fastscripts"
    "com.rogueamoeba.soundsource"
    "io.tailscale.ipn.macsys"
    "org.sbarex.QLMarkdown"
  ];
}
