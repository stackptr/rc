let
  keys = with (import ../keys.nix); [glyph Rhizome];
in {
  "hosts/glyph/secrets/filebrowser-env.age".publicKeys = keys;
  "hosts/glyph/secrets/pushover-app-token.age".publicKeys = keys;
  "hosts/glyph/secrets/pushover-user-token.age".publicKeys = keys;
  "hosts/glyph/secrets/kagi-api-key.age".publicKeys = keys;
  "hosts/glyph/secrets/context7-api-key.age".publicKeys = keys;
  "hosts/glyph/secrets/open-terminal-env.age".publicKeys = keys;
  "hosts/glyph/secrets/open-webui-api-key.age".publicKeys = keys;
  "hosts/glyph/secrets/open-webui-env.age".publicKeys = keys;
  "hosts/glyph/secrets/grafana-mcp-token.age".publicKeys = keys;
  "hosts/glyph/secrets/graphite-auth-token.age".publicKeys = keys;
  "hosts/glyph/secrets/attic-credentials.age".publicKeys = keys;
}
