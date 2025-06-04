{
  config,
  pkgs,
  lib,
  ...
}: {
  security.pam.services.sudo_local.touchIdAuth = true;
  
  system.disableUpdates = [
    "at.eggerapps.Postico"
    "com.colliderli.iina"
    "com.daisydiskapp.DaisyDiskStandAlone"
    "com.jordanbaird.Ice"
    "com.panic.Nova"
    "com.red-sweater.fastscripts"
    "com.rogueamoeba.soundsource"
    "io.tailscale.ipn.macsys"
    "org.sbarex.QLMarkdown"
  ];
}
