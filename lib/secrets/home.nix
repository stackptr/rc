let
  keys = with (import ../keys.nix); [home Rhizome];
in {
  "home/secrets/aichat-env.age".publicKeys = keys;
  "home/secrets/atuin-key.age".publicKeys = keys;
}
