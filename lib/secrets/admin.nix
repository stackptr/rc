# Rules for secrets no host decrypts: encrypted to the admin YubiKeys only.
# lib/admin/github-apps/teleomycete.age is the exception: glyph decrypts it,
# so its rule is in glyph.nix.
let
  keys = import ../keys.nix;
in {
  "lib/admin/ops-state-passphrase.age".publicKeys = keys.admins;
  # GitHub App private keys that stackptr/ops seals into environments:
  # teleoid's into every agent repo's `approve`, teleotrope's into rc's
  # `update`. The only copies; GitHub shows a key once.
  "lib/admin/github-apps/teleoid.age".publicKeys = keys.admins;
  "lib/admin/github-apps/teleotrope.age".publicKeys = keys.admins;
  # stackptr/ops's own apps: teleopsis plans (its `plan` environment),
  # teleozyme applies (`production`)
  "lib/admin/github-apps/teleopsis.age".publicKeys = keys.admins;
  "lib/admin/github-apps/teleozyme.age".publicKeys = keys.admins;
}
