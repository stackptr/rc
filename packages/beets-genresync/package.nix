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
    rev = "64f8e5fb048e68dd1ad86000710ed9eb03d4ea6a";
    hash = "sha256-UBpuGnQfmW70Y5WanTBold0Z/y9H0RfmUDyajA2OYik=";
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
