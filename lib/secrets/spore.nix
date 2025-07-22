let
  keys = with (import ../keys.nix); [spore Petrichor Rhizome];
in {
  "hosts/spore/secrets/cloudflare-dns.age".publicKeys = keys;
  "hosts/spore/secrets/homepage-env.age".publicKeys = keys;
  "hosts/spore/secrets/jwt-secret.age".publicKeys = keys;
  "hosts/spore/secrets/mastodon-s3-env.age".publicKeys = keys;
  "hosts/spore/secrets/mastodon-secret-key-base.age".publicKeys = keys;
  "hosts/spore/secrets/mastodon-vapid-public-key.age".publicKeys = keys;
  "hosts/spore/secrets/mastodon-vapid-private-key.age".publicKeys = keys;
  "hosts/spore/secrets/notifier-smtp-password.age".publicKeys = keys;
  "hosts/spore/secrets/restic-env.age".publicKeys = keys;
  "hosts/spore/secrets/restic-password.age".publicKeys = keys;
  "hosts/spore/secrets/session-secret.age".publicKeys = keys;
  "hosts/spore/secrets/storage-encryption-key.age".publicKeys = keys;
  "hosts/spore/secrets/tailscale-auth-key.age".publicKeys = keys;
}
