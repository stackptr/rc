self: super: let
  version = "1.30.3";
in {
  gallery-dl = super.gallery-dl.overrideAttrs (finalAttrs: {
    inherit version;
    src = super.fetchFromGitHub {
      owner = "mikf";
      repo = "gallery-dl";
      tag = "v${version}";
      hash = "sha256-zkyPn18ER6Xlyo4ITC8TDk9vVHubbyfJHKxQF4JodHY=";
    };
  });
}
