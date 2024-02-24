{
  lib,
  config,
  pkgs,
  keys,
  ...
}: {
  users = {
    mutableUsers = false;
    users.mu = {
      isNormalUser = true;
      extraGroups = ["wheel"];
      shell = pkgs.zsh;
    };
  };
  users.users.root.openssh.authorizedKeys.keys = [
    keys.Petrichor
    keys.Rhizome
  ];
  users.users.mu.openssh.authorizedKeys.keys = [
    keys.Petrichor
    keys.Rhizome
  ];
  security.sudo.wheelNeedsPassword = false;
  security.pam.sshAgentAuth.authorizedKeysFiles = lib.mkForce ["/etc/ssh/authorized_keys.d/%u"];
}
