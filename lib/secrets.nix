let
  keys = with (import ./keys.nix); [glyph Petrichor Rhizome spore zeta];
in {
  "hosts/glyph/secrets/pushover-app-token.age".publicKeys = keys;
  "hosts/glyph/secrets/pushover-user-token.age".publicKeys = keys;
  "hosts/spore/secrets/cloudflare-dns.age".publicKeys = keys;
  "hosts/spore/secrets/homepage-env.age".publicKeys = keys;
  "hosts/spore/secrets/jwt-secret.age".publicKeys = keys;
  "hosts/spore/secrets/mastodon-s3-env.age".publicKeys = keys;
  "hosts/spore/secrets/mastodon-secret-key-base.age".publicKeys = keys;
  "hosts/spore/secrets/mastodon-otp-secret.age".publicKeys = keys;
  "hosts/spore/secrets/mastodon-vapid-public-key.age".publicKeys = keys;
  "hosts/spore/secrets/mastodon-vapid-private-key.age".publicKeys = keys;
  "hosts/spore/secrets/notifier-smtp-password.age".publicKeys = keys;
  "hosts/spore/secrets/restic-env.age".publicKeys = keys;
  "hosts/spore/secrets/restic-password.age".publicKeys = keys;
  "hosts/spore/secrets/session-secret.age".publicKeys = keys;
  "hosts/spore/secrets/storage-encryption-key.age".publicKeys = keys;
  "hosts/spore/secrets/tailscale-auth-key.age".publicKeys = keys;
  "hosts/zeta/secrets/wireless.age".publicKeys = keys;
  "hosts/zeta/secrets/dd-agent.age".publicKeys = keys;
  "hosts/zeta/secrets/znc-conf.age".publicKeys = keys;
}
