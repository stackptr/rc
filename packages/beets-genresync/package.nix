{
  lib,
  fetchFromGitHub,
  buildPythonPackage,
  setuptools,
  musicbrainzngs,
  requests,
}:
buildPythonPackage rec {
  pname = "beets-genresync";
  version = "0.1.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "stackptr";
    repo = "beets-genresync";
    rev = "a12c30fdfde74ca84a34ce999c27126fab0d1923";
    hash = "sha256-qd9UpFy2Vwf5rJDkUrIy5VlVdmyW5yZ5NBa0apfnuUE=";
  };

  build-system = [
    setuptools
  ];

  dependencies = [
    musicbrainzngs
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
