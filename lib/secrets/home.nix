# Home-manager secrets, decrypted with the shared `home` key
let
  keys = import ../keys.nix;
  recipients = [keys.home] ++ keys.admins;
in {
  "home/secrets/aichat-env.age".publicKeys = recipients;
  "home/secrets/opencode-env.age".publicKeys = recipients;
}
