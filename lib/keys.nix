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
  }
