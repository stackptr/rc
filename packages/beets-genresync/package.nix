{
  lib,
  fetchFromGitHub,
  buildPythonPackage,
  setuptools,
  requests,
}:
buildPythonPackage rec {
  pname = "beets-genresync";
  version = "0.1.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "stackptr";
    repo = "beets-genresync";
    rev = "be04cf0f8828028d74d75e9cc81c1e60f2a046fd";
    hash = "sha256-ipYA3Pyi1VrIjs2Vkji7Xexh3xpwlJ4+PVsDLx5V+sk=";
  };

  build-system = [
    setuptools
  ];

  dependencies = [
    requests
  ];

  # No test suite yet.
  doCheck = false;

  meta = {
    description = "Beets plugin that syncs album genres from MusicBrainz and Discogs";
    homepage = "https://github.com/stackptr/beets-genresync";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
