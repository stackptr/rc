{
  config,
  lib,
  pkgs,
  ...
}: {
  # Use Pantheon and LightDM
  services.xserver = {
    enable = true;
    desktopManager.pantheon.enable = true;
    displayManager.lightdm.enable = true;
  };

  # Disable most stock apps
  services.pantheon.apps.enable = false;
  environment.systemPackages = with pkgs; [
    pantheon.elementary-files
    pantheon.elementary-terminal
  ];
}
