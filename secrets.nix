let
  readKey = host: builtins.readFile ./hosts/${host}/key.pub;
  keys = map readKey [ "ohm" "Petrichor" "Rhizome" "zeta"];
in {
  "hosts/zeta/secrets/userpassword.age".publicKeys = keys;
  "hosts/zeta/secrets/wireless.age".publicKeys = keys;
  "hosts/zeta/secrets/dd-agent.age".publicKeys = keys;
}
