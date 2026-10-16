# A home-manager secret, so it decrypts with the `home` key, not lobtop's
let
  keys = import ../keys.nix;
in {
  "hosts/lobtop/secrets/otel-token.age".publicKeys = [keys.home] ++ keys.admins;
}
