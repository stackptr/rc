# Rules for secrets no host decrypts: encrypted to the admin YubiKeys only.
let
  keys = import ../keys.nix;
in {
  "lib/admin/ops-state-passphrase.age".publicKeys = keys.admins;
}
