# SSH configuration and key management
{
  lib,
  config,
  pkgs,
  keys,
  ...
}: {
  users.users.root.openssh.authorizedKeys.keys = [
    keys.Rhizome
    keys.glyph
  ];

  users.users.mu.openssh.authorizedKeys.keys = [
    keys.Rhizome
    keys.glyph
  ];

  security.pam.sshAgentAuth.authorizedKeysFiles = lib.mkForce ["/etc/ssh/authorized_keys.d/%u"];
}
