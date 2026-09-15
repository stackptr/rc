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
    rev = "52d4a293d7d7f32fca4a3433e061f99610dd5263";
    hash = "sha256-b7OFNun3g1/I0hgNFfMbXyg4qKceOsj5hqmE6A7l1DU=";
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
