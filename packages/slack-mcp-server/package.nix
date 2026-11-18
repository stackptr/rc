{
  lib,
  fetchFromGitHub,
  buildGoModule,
}:
# Pinned: upstream has been quiet since this release (May 2026), so expect no
# fixes. If a Slack or MCP change breaks it, replace it with a small server
# over conversations.history rather than forking.
buildGoModule rec {
  pname = "slack-mcp-server";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "korotovsky";
    repo = "slack-mcp-server";
    rev = "v${version}";
    hash = "sha256-I4f6yKV0BXtaxnqi/XNID+Pwl2mWjSqxIHhb07U7sc4=";
  };

  vendorHash = "sha256-+uQRODO9oL8mGKBmdghTxE6R9Fz+3GJFVTi17306gT8=";

  subPackages = ["cmd/slack-mcp-server"];

  # The tests include integration tests that call Slack and OpenAI.
  doCheck = false;

  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
    "-X github.com/korotovsky/slack-mcp-server/pkg/version.Version=${version}"
  ];

  meta = with lib; {
    description = "MCP server for Slack workspaces";
    homepage = "https://github.com/korotovsky/slack-mcp-server";
    license = licenses.mit;
    mainProgram = "slack-mcp-server";
  };
}
