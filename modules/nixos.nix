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
      description = "Corey";
      isNormalUser = true;
      extraGroups = ["wheel"];
      shell = pkgs.zsh;
    };
  };
  users.users.root.openssh.authorizedKeys.keys = [
    keys.Petrichor
    keys.Rhizome
    keys.glyph
  ];
  users.users.mu.openssh.authorizedKeys.keys = [
    keys.Petrichor
    keys.Rhizome
    keys.glyph
  ];
  security.sudo.wheelNeedsPassword = false;
  security.sudo.extraConfig = ''
    Defaults env_keep += "EDITOR"
  '';
  security.pam.sshAgentAuth.authorizedKeysFiles = lib.mkForce ["/etc/ssh/authorized_keys.d/%u"];
}
