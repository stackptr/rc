# SSH configuration and key management
{
  lib,
  config,
  pkgs,
  keys,
  hostname,
  ...
}: let
  # sshd rejects a signature from these keys unless the YubiKey checked the
  # FIDO2 PIN, not just a touch.
  yubikeys = map (k: "verify-required ${k}") keys.yubikeys;
in {
  # People log in only with the YubiKeys. Unattended access is root only:
  # CI's deploy key everywhere, and glyph's client key on spore and zeta
  # (glyph already signs every host's binary cache, so it adds no reach;
  # nothing gets into glyph unattended).
  users.users.root.openssh.authorizedKeys.keys =
    [keys.deploy]
    ++ yubikeys
    ++ lib.optional (hostname != "glyph") keys.clients.glyph;

  users.users.mu.openssh.authorizedKeys.keys = yubikeys;

  # Keys only. Both default to true in NixOS, and mu has a password on
  # glyph and spore for console logins.
  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
  };

  security.pam.sshAgentAuth.authorizedKeysFiles = lib.mkForce ["/etc/ssh/authorized_keys.d/%u"];
}
