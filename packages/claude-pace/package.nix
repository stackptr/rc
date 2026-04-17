{
  lib,
  fetchFromGitHub,
  stdenv,
  makeWrapper,
  curl,
  git,
  jq,
}:
stdenv.mkDerivation rec {
  pname = "claude-pace";
  version = "0.7.3";

  src = fetchFromGitHub {
    owner = "Astro-Han";
    repo = "claude-pace";
    rev = "v${version}";
    hash = "sha256-88qKvC+8Fu2IvBkU3SGbCj2tL78kh4yux4fUE1mo5Jw=";
  };

  nativeBuildInputs = [makeWrapper];

  installPhase = ''
    mkdir -p $out/bin
    cp claude-pace.sh $out/bin/claude-pace
    chmod +x $out/bin/claude-pace
    wrapProgram $out/bin/claude-pace \
      --prefix PATH : ${lib.makeBinPath [curl git jq]}
  '';

  meta = with lib; {
    description = "Pace-aware statusline for Claude Code with rate limit tracking and pace delta";
    homepage = "https://github.com/Astro-Han/claude-pace";
    license = licenses.mit;
    mainProgram = "claude-pace";
    platforms = platforms.unix;
  };
}
