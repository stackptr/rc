# User secrets shared by several hosts. Each host decrypts them with its own
# host key and gives them to its user (owner = username).
let
  keys = import ../keys.nix;
in {
  "home/secrets/aichat-env.age".publicKeys = [keys.glyph keys.Rhizome keys.Stroma] ++ keys.admins;
}
