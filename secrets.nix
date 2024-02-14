let
  firstLine = str: builtins.head (builtins.split "\n" str);
  readKey = host:
    firstLine (builtins.readFile ./hosts/${host}/key.pub);
  keys = map readKey ["ohm" "Petrichor" "Rhizome" "zeta"];
in {
  "hosts/ohm/secrets/cloudflare-dns.age".publicKeys = keys;
  "hosts/zeta/secrets/userpassword.age".publicKeys = keys;
  "hosts/zeta/secrets/wireless.age".publicKeys = keys;
  "hosts/zeta/secrets/dd-agent.age".publicKeys = keys;
}
