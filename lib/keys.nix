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
      "Rhizome"
      "spore"
      "Stroma"
      "zeta"
    ];
in
  builtins.listToAttrs hostKeyPairs
  // {
    identity = firstLine (builtins.readFile ./auth.pub);
    home = firstLine (builtins.readFile ./../home/key.pub);
    deploy = firstLine (builtins.readFile ./deploy.pub);
  }
