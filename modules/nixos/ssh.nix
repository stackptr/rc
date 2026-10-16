# SSH configuration and key management
{
  lib,
  config,
  pkgs,
  keys,
  ...
}: let
  # sshd rejects a signature from these keys unless the YubiKey checked the
  # FIDO2 PIN, not just a touch.
  yubikeys = map (k: "verify-required ${k}") keys.yubikeys;
in {
  users.users.root.openssh.authorizedKeys.keys =
    [
      keys.users.Rhizome
      keys.glyph
      keys.deploy
    ]
    ++ yubikeys;

  users.users.mu.openssh.authorizedKeys.keys =
    [
      keys.users.Rhizome
      keys.glyph
      keys.Stroma
      keys.users.lobtop
    ]
    ++ yubikeys;

  # Keys only. Both default to true in NixOS, and mu has a password on
  # glyph and spore for console logins.
  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
  };

  security.pam.sshAgentAuth.authorizedKeysFiles = lib.mkForce ["/etc/ssh/authorized_keys.d/%u"];
}
