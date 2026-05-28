let
  keys = with (import ../keys.nix); [home deploy];
in {
  "hosts/lobtop/secrets/otel-token.age".publicKeys = keys;
}
