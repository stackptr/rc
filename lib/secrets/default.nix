# Global secrets that multiple hosts need access to
let
  keys = import ../keys.nix;
  recipients = [keys.glyph keys.spore] ++ keys.admins;
in {
  "secrets/restic-env.age".publicKeys = recipients;
  "secrets/restic-password.age".publicKeys = recipients;
}
