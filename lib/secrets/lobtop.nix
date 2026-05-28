let
  keys = with (import ../keys.nix); [lobtop deploy];
in {
  "hosts/lobtop/secrets/otel-token.age".publicKeys = keys;
}
