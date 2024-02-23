let
  keys = with (import ./lib/keys.nix); [ohm Petrichor Rhizome zeta];
in {
  "hosts/ohm/secrets/cloudflare-dns.age".publicKeys = keys;
  "hosts/ohm/secrets/jwt-secret.age".publicKeys = keys;
  "hosts/ohm/secrets/notifier-smtp-password.age".publicKeys = keys;
  "hosts/ohm/secrets/session-secret.age".publicKeys = keys;
  "hosts/ohm/secrets/storage-encryption-key.age".publicKeys = keys;
  "hosts/zeta/secrets/userpassword.age".publicKeys = keys;
  "hosts/zeta/secrets/wireless.age".publicKeys = keys;
  "hosts/zeta/secrets/dd-agent.age".publicKeys = keys;
}
