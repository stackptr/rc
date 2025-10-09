let
  keys = with (import ../keys.nix); [glyph Rhizome];
in {
  "hosts/glyph/secrets/pushover-app-token.age".publicKeys = keys;
  "hosts/glyph/secrets/pushover-user-token.age".publicKeys = keys;
}
