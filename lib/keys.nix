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
      "nazar"
      "Petrichor"
      "Rhizome"
      "zeta"
    ];
in
  builtins.listToAttrs hostKeyPairs
