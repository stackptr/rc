# lib/secrets/admin.nix: secrets no host decrypts, only the admin YubiKeys
let
  keys = import ../keys.nix;
in {
  "lib/admin/ops-state-passphrase.age".publicKeys = keys.admins;
}
