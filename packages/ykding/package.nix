{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "ykding";
  version = "0.5.0";

  # Pinned to a commit, not the Homebrew tap: the tap would upgrade on every
  # switch. One author, one script, so read the diff before bumping.
  src = fetchFromGitHub {
    owner = "onyb";
    repo = "ykding";
    rev = "6920873fbaa095d2857d29c74a15402b53079839";
    hash = "sha256-woSd8M9IJ+47N+0anyucJPTZ/lfWtC26lLco6ASm6eM=";
  };

  # Uses only macOS's own tools (/bin/zsh, /usr/bin/log, afplay, osascript).
  dontPatchShebangs = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 ykding $out/bin/ykding
    runHook postInstall
  '';

  meta = with lib; {
    description = "Sound and notification whenever a YubiKey is waiting for a touch";
    homepage = "https://github.com/onyb/ykding";
    license = licenses.mit;
    mainProgram = "ykding";
    platforms = platforms.darwin;
  };
}
