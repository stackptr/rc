{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:
buildNpmPackage rec {
  pname = "freshrss-mcp";
  version = "0.3.2";

  src = fetchFromGitHub {
    owner = "ni-c";
    repo = "freshrss-mcp";
    rev = "v${version}";
    hash = "sha256-m6AmRJKhMLHUIQ7waHsKpS6QjDk83XTCl4ovlTbIGy4=";
  };

  npmDepsHash = "sha256-u5de0xmvbKDtY1rvsxEBu1g0b+OcGuvAe38Q21Tjl3I=";

  nodejs = nodejs_22;

  meta = with lib; {
    description = "MCP server for FreshRSS over its Google Reader API";
    homepage = "https://github.com/ni-c/freshrss-mcp";
    license = licenses.mit;
    maintainers = [];
    mainProgram = "freshrss-mcp";
    platforms = platforms.unix;
  };
}
