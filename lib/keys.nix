let
  firstLine = str: builtins.head (builtins.split "\n" str);
  readKey = host:
    firstLine (builtins.readFile ./../hosts/${host}/key.pub);
  hostKeyPairs =
    map (h: {
      name = h;
      value = readKey h;
    }) [
      "glyph"
      "lobtop"
      "Rhizome"
      "spore"
      "Stroma"
      "zeta"
    ];
in
  builtins.listToAttrs hostKeyPairs
  // {
    home = firstLine (builtins.readFile ./../home/key.pub);
    deploy = firstLine (builtins.readFile ./deploy.pub);

    # agenix admin recipients: age-plugin-yubikey keys (PIV slot 1, PIN once,
    # touch cached). Identity files are in lib/admin/; b is the offline spare.
    admins = [
      "age1yubikey1q0h7amkmv8va7zvzd9k64l603qvafuxklq8467jsmgrhhdsc0cjdc2x33cq" # yubikey-a
      "age1yubikey1qvwy5zdaqkptwxsjx5z25jtncl4tp00m4nz6s6swnavayshlja7mjxtcn46" # yubikey-b
    ];
  }
