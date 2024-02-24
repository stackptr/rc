{
  config,
  pkgs,
  keys,
  lib,
  ...
}: {
  users = {
    mutableUsers = false;
    users.mu = {
      isNormalUser = true;
      extraGroups = ["wheel" "docker"];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        keys.Petrichor
        keys.Rhizome
      ];
    };
    users.root.openssh.authorizedKeys.keys = [keys.Petrichor keys.Rhizome];
  };

  security.sudo.wheelNeedsPassword = false;
  security.pam.sshAgentAuth.authorizedKeysFiles = lib.mkForce ["/etc/ssh/authorized_keys.d/%u"];

  system.stateVersion = "23.11";
}
