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
      "Petrichor"
      "Rhizome"
      "spore"
      "zeta"
    ];
in
  builtins.listToAttrs hostKeyPairs
