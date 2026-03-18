{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  port = 8888;
  baseUrl = "http://127.0.0.1:${toString port}";

  # Shared model defaults
  defaultCapabilities = {
    file_context = true;
    vision = true;
    file_upload = true;
    web_search = true;
    image_generation = true;
    code_interpreter = true;
    citations = true;
    status_updates = true;
    builtin_tools = true;
  };

  defaultBuiltinTools = {
    time = true;
    memory = true;
    chats = true;
    notes = true;
    knowledge = true;
    channels = true;
    web_search = true;
    image_generation = true;
    code_interpreter = true;
  };

  defaultMeta = {
    capabilities = defaultCapabilities;
    toolIds = ["server:mcp:glyph"];
    defaultFeatureIds = ["web_search" "code_interpreter"];
    builtinTools = defaultBuiltinTools;
  };

  # Active models — listed models are enabled with full config.
  # All other models from the API provider are deactivated automatically.
  models = {
    "claude-sonnet-4-6".name = "Claude Sonnet 4.6";
    "claude-opus-4-6".name = "Claude Opus 4.6";
    "claude-haiku-4-5-20251001".name = "Claude Haiku 4.5";
  };

  modelIds = builtins.toJSON (builtins.attrNames models);
in {
  age.secrets.open-webui-env.file = ./../secrets/open-webui-env.age;
  age.secrets.open-webui-api-key = {
    file = ./../secrets/open-webui-api-key.age;
    mode = "440";
  };

  systemd.services.open-webui.restartTriggers = [config.age.secrets.open-webui-env.file];

  # Sync model configuration after open-webui starts
  systemd.timers.open-webui-model-sync = {
    description = "Trigger Open WebUI model sync";
    wantedBy = ["timers.target"];
    restartTriggers = [(builtins.hashString "sha256" (builtins.toJSON models))];
    timerConfig.OnActiveSec = "10s";
  };

  systemd.services.open-webui-model-sync = {
    description = "Sync model configuration with Open WebUI";
    after = ["open-webui.service"];
    requires = ["open-webui.service"];
    restartIfChanged = false;
    path = [pkgs.curl pkgs.jq];
    script = let
      mkModelForm = id: attrs:
        builtins.toJSON {
          inherit id;
          is_active = true;
          name = attrs.name or id;
          meta = defaultMeta // (attrs.meta or {});
          params = {function_calling = "native";} // (attrs.params or {});
        };

      mkModelUpdate = id: attrs: let
        form = mkModelForm id attrs;
      in ''
        update_model "${id}" '${form}' &
      '';
    in ''
      API_KEY=$(cat ${config.age.secrets.open-webui-api-key.path})
      ACTIVE_IDS='${modelIds}'

      update_model() {
        local id=$1 form=$2
        echo "Configuring $id..."
        # Try update first; if model has no DB entry yet, create it
        http_code=$(curl -s -o /dev/null -w '%{http_code}' -X POST \
          -H "Authorization: Bearer $API_KEY" \
          -H "Content-Type: application/json" \
          -d "$form" \
          "${baseUrl}/api/v1/models/model/update")

        if [ "$http_code" = "200" ]; then
          echo "$id: updated."
        elif [ "$http_code" = "401" ]; then
          # Model has no DB entry — create it
          http_code=$(curl -s -o /dev/null -w '%{http_code}' -X POST \
            -H "Authorization: Bearer $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$form" \
            "${baseUrl}/api/v1/models/create")
          if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
            echo "$id: created."
          else
            echo "ERROR: failed to create $id (HTTP $http_code)"
          fi
        else
          echo "ERROR: failed to update $id (HTTP $http_code)"
        fi
      }

      # Wait for open-webui to be ready
      for i in $(seq 1 30); do
        if curl -sf "${baseUrl}/api/models" -H "Authorization: Bearer $API_KEY" >/dev/null 2>&1; then
          break
        fi
        echo "Waiting for Open WebUI (attempt $i/30)..."
        sleep 2
      done

      # Activate and configure listed models
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList mkModelUpdate models)}
      wait

      # Deactivate all unlisted models that are currently active
      all_models=$(curl -sf -H "Authorization: Bearer $API_KEY" \
        "${baseUrl}/api/models" 2>/dev/null)
      if [ -n "$all_models" ]; then
        echo "$all_models" \
          | jq -r '.data[] | select(.info.is_active == true or .info == null) | .id' \
          | while read -r id; do
              if ! echo "$ACTIVE_IDS" | jq -e --arg id "$id" 'index($id)' >/dev/null 2>&1; then
                curl -sf -X POST -H "Authorization: Bearer $API_KEY" \
                  "${baseUrl}/api/v1/models/model/toggle?id=$id" >/dev/null 2>&1
                echo "$id: deactivated."
              fi
            done
      else
        echo "WARNING: could not fetch model list for deactivation"
      fi
    '';
  };

  services.open-webui = {
    enable = true;
    package = pkgs.open-webui.overridePythonAttrs (old: {
      dependencies = old.dependencies ++ old.optional-dependencies.postgres;
    });
    inherit port;
    host = "0.0.0.0";
    environmentFile = config.age.secrets.open-webui-env.path;
    environment = {
      ENABLE_OLLAMA_API = "False";
      ENABLE_SIGNUP = "False";
      ENABLE_PERSISTENT_CONFIG = "False";
      WEBUI_URL = "https://chat.zx.dev";
      WEBUI_SESSION_COOKIE_SECURE = "True";
      CORS_ALLOW_ORIGIN = "https://chat.zx.dev";
      ENABLE_VERSION_UPDATE_CHECK = "False";

      # OIDC via Pocket ID
      ENABLE_OAUTH_SIGNUP = "true";
      OAUTH_PROVIDER_NAME = "Pocket ID";
      OPENID_PROVIDER_URL = "https://id.zx.dev/.well-known/openid-configuration";
      OAUTH_MERGE_ACCOUNTS_BY_EMAIL = "true";
      OAUTH_SCOPES = "openid email profile groups";
      ENABLE_OAUTH_ROLE_MANAGEMENT = "true";
      ENABLE_OAUTH_GROUP_MANAGEMENT = "true";
      ENABLE_OAUTH_GROUP_CREATION = "true";
      OAUTH_ROLES_CLAIM = "groups";
      OAUTH_ALLOWED_ROLES = "users, admins";
      OAUTH_ADMIN_ROLES = "admins";
      ENABLE_LOGIN_FORM = "false";
      ENABLE_API_KEYS = "True";
      USER_PERMISSIONS_FEATURES_API_KEYS = "True";
      DATABASE_URL = "postgresql:///open-webui?host=/run/postgresql";

      # Web search via Kagi (API key in open-webui-env.age)
      ENABLE_WEB_SEARCH = "True";
      ENABLE_SEARCH_QUERY_GENERATION = "True";
      WEB_SEARCH_ENGINE = "kagi";

      # System prompt sourced from llm-profile flake input (github:stackptr/llm-profile)
      DEFAULT_SYSTEM_PROMPT = builtins.readFile "${inputs.llm-profile}/README.md";

      # MCP tool server: MCPJungle gateway on glyph (aggregates all registered MCP servers)
      TOOL_SERVER_CONNECTIONS = builtins.toJSON [
        {
          type = "mcp";
          url = "http://localhost:8090";
          path = "mcp";
          auth_type = "none";
          key = "";
          config.enable = true;
          info = {
            id = "glyph";
            name = "Glyph";
            description = "MCP gateway";
          };
        }
      ];
    };
  };
}
