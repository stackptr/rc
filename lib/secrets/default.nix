# Global secrets that multiple hosts need access to
let
  keys = with (import ../keys.nix); [glyph spore Rhizome];
in {
  "secrets/restic-env.age".publicKeys = keys;
  "secrets/restic-password.age".publicKeys = keys;
}
