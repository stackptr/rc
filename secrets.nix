let
  keys = with (import ./lib/keys.nix); [glyph nazar Petrichor Rhizome zeta];
in {
  "hosts/glyph/secrets/pushover-app-token.age".publicKeys = keys;
  "hosts/glyph/secrets/pushover-user-token.age".publicKeys = keys;
  "hosts/nazar/secrets/cloudflare-dns.age".publicKeys = keys;
  "hosts/nazar/secrets/dendrite-env.age".publicKeys = keys;
  "hosts/nazar/secrets/dendrite-private-key.age".publicKeys = keys;
  "hosts/nazar/secrets/jwt-secret.age".publicKeys = keys;
  "hosts/nazar/secrets/mastodon-s3-env.age".publicKeys = keys;
  "hosts/nazar/secrets/mastodon-secret-key-base.age".publicKeys = keys;
  "hosts/nazar/secrets/mastodon-otp-secret.age".publicKeys = keys;
  "hosts/nazar/secrets/mastodon-vapid-public-key.age".publicKeys = keys;
  "hosts/nazar/secrets/mastodon-vapid-private-key.age".publicKeys = keys;
  "hosts/nazar/secrets/notifier-smtp-password.age".publicKeys = keys;
  "hosts/nazar/secrets/restic-env.age".publicKeys = keys;
  "hosts/nazar/secrets/restic-password.age".publicKeys = keys;
  "hosts/nazar/secrets/session-secret.age".publicKeys = keys;
  "hosts/nazar/secrets/storage-encryption-key.age".publicKeys = keys;
  "hosts/zeta/secrets/wireless.age".publicKeys = keys;
  "hosts/zeta/secrets/dd-agent.age".publicKeys = keys;
}
