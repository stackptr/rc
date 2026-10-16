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
    keys.deploy
  ];

  users.users.mu.openssh.authorizedKeys.keys = [
    keys.Rhizome
    keys.glyph
    keys.Stroma
    keys.lobtop
  ];

  # Keys only. Both default to true in NixOS, and mu has a password on
  # glyph and spore for console logins.
  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
  };

  security.pam.sshAgentAuth.authorizedKeysFiles = lib.mkForce ["/etc/ssh/authorized_keys.d/%u"];
}
