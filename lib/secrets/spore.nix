import ./mk-host.nix "spore" [
  "cloudflare-dns"
  "docs-htpasswd"
  "homepage-env"
  "mastodon-s3-env"
  "mastodon-secret-key-base"
  "mastodon-vapid-public-key"
  "mastodon-vapid-private-key"
  "notifier-smtp-password"
  "oauth2-proxy-env"
  "pocket-id-encryption-key"
  "tailscale-auth-key"
  "user-password"
]
