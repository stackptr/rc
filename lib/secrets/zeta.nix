let
  keys = with (import ../keys.nix); [zeta Rhizome];
in {
  "hosts/zeta/secrets/wireless.age".publicKeys = keys;
  "hosts/zeta/secrets/dd-agent.age".publicKeys = keys;
  "hosts/zeta/secrets/znc-conf.age".publicKeys = keys;
}
