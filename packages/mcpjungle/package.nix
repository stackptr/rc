{
  lib,
  fetchFromGitHub,
  buildGoModule,
}:
buildGoModule rec {
  pname = "mcpjungle";
  version = "0.3.5";

  src = fetchFromGitHub {
    owner = "mcpjungle";
    repo = "mcpjungle";
    rev = version;
    hash = "sha256-Q/ASyI6DygmYa284wk2pmYgVtPKRummnyh60v+Ri7bU=";
  };

  vendorHash = "sha256-pvCDf7Y+LiIOiZ0O/bJMzkf75o7HQbYpF01yFY4J9Yg=";

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
