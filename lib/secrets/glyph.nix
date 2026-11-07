let
  keys = import ../keys.nix;
in
  import ./mk-host.nix "glyph" [
    "filebrowser-env"
    "slack-bot-token"
    "grafana-client-secret"
    "grafana-secret-key"
    "kagi-api-key"
    "context7-api-key"
    "open-terminal-env"
    "open-webui-api-key"
    "open-webui-env"
    "grafana-mcp-token"
    "attic-credentials"
    "user-password"
    "obsidian-auth-token"
    "navidrome-env"
    "pgadmin-client-secret"
    "pgadmin-password"
    "opencode-env"
    "paseo-env"
    "claude-code-env"
    "restic-env"
    "restic-password"
    "ssh-client-key"
    "hermes-omlx-env"
    "hermes-slack-env"
    "hermes-freshrss-env"
  ]
  // {
    # teleomycete's key: kept with the other GitHub App keys, but glyph mints
    # the agents' tokens with it, so unlike them it's also encrypted to glyph
    "lib/admin/github-apps/teleomycete.age".publicKeys = [keys.glyph] ++ keys.admins;
  }
