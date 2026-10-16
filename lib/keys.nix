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
    deploy = firstLine (builtins.readFile ./deploy.pub);

    # SSH login keys (~/.ssh/id_ed25519.pub) of the hosts people SSH from, for
    # authorized_keys only. The attributes above are host keys: agenix
    # recipients and known_hosts.
    users = {
      Rhizome = firstLine (builtins.readFile ./../hosts/Rhizome/user.pub);
      lobtop = firstLine (builtins.readFile ./../hosts/lobtop/user.pub);
    };

    # agenix admin recipients: age-plugin-yubikey keys (PIV slot 1, PIN once,
    # touch cached). Identity files are in lib/admin/; b is the offline spare.
    admins = [
      "age1yubikey1q0h7amkmv8va7zvzd9k64l603qvafuxklq8467jsmgrhhdsc0cjdc2x33cq" # yubikey-a
      "age1yubikey1qvwy5zdaqkptwxsjx5z25jtncl4tp00m4nz6s6swnavayshlja7mjxtcn46" # yubikey-b
    ];
  }
