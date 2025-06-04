# Sudo configuration and privilege escalation
{
  lib,
  config,
  pkgs,
  ...
}: {
  security.sudo.wheelNeedsPassword = false;
  security.sudo.extraConfig = ''
    Defaults env_keep += "EDITOR"
  '';
}
