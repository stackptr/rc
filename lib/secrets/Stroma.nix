let
  keys = with (import ../keys.nix); [Stroma Rhizome];
in {
  "hosts/Stroma/secrets/omlx-monitoring-key.age".publicKeys = keys;
}
