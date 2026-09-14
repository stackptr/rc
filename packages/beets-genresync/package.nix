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
    rev = "2c035e1591c9b29a2a321ea949fa4cc125c0dd05";
    hash = "sha256-HrmdXYF2Hv8Xk8parzA+KzXT8fS6g0+5BMM1HnXd+HU=";
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
