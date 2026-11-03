{
  lib,
  fetchFromGitHub,
  buildGoModule,
}:
buildGoModule rec {
  pname = "mcpjungle";
  version = "0.4.6";

  src = fetchFromGitHub {
    owner = "mcpjungle";
    repo = "mcpjungle";
    rev = version;
    hash = "sha256-XzszhbkQENeUgOOVBw7dsqZWR7hU3yLYOAclf3E9gy8=";
  };

  vendorHash = "sha256-3uatBXXdQzqGuhFuLkpmoMkYYqUMt1dFqm7vuazMLqs=";

  # The dev-mode dashboard is a separate npm build that upstream's release
  # pipeline copies into internal/dashboardui/dist before go:embed reads it.
  # Embed a placeholder instead; the gateway and API don't depend on it.
  preBuild = ''
    mkdir -p internal/dashboardui/dist
    echo '<!doctype html><title>MCPJungle</title>' > internal/dashboardui/dist/index.html
  '';

  # Tests require HOME to exist (tilde expansion); skip in sandbox
  doCheck = false;

  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
    "-X github.com/mcpjungle/mcpjungle/pkg/version.Version=${version}"
  ];

  meta = with lib; {
    description = "Self-hosted MCP Gateway";
    homepage = "https://github.com/mcpjungle/mcpjungle";
    license = licenses.mit;
    mainProgram = "mcpjungle";
  };
}
