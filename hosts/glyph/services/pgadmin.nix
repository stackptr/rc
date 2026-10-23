# pgAdmin (glyph:5050, db.zx.dev via spore) for browsing and editing every
# database in glyph's Postgres. Logins go through Pocket ID only; the server
# list and the one user allowed in are declared here.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.pgadmin;
  cli = "${cfg.package}/bin/pgadmin4-cli";

  # The Pocket ID account allowed in: pgAdmin matches OIDC logins on the
  # email claim, and OAUTH2_AUTO_CREATE_USER is off.
  user = "corey@zx.dev";

  # pg_hba trusts the socket, so there's no password. pgAdmin still prompts
  # for one unless the server has a saved password, passfile, PassExecCommand
  # or libpq service, so it gets a service with the same connection.
  conn = {
    host = "/run/postgresql";
    port = config.services.postgresql.settings.port;
    user = "pgadmin";
  };
  serviceFile = pkgs.writeText "pg_service.conf" (lib.generators.toINI {} {glyph = conn;});

  # One entry covers every database on the server
  servers = pkgs.writeText "pgadmin-servers.json" (builtins.toJSON {
    Servers."1" = {
      Name = "glyph";
      Group = "Servers";
      Service = "glyph";
      Host = conn.host;
      Port = conn.port;
      MaintenanceDB = "postgres";
      Username = conn.user;
    };
  });
in {
  age.secrets.pgadmin-password.file = ./../secrets/pgadmin-password.age;
  age.secrets.pgadmin-client-secret.file = ./../secrets/pgadmin-client-secret.age;

  services.pgadmin = {
    enable = true;
    # Required by the module, but unused: "internal" isn't in
    # AUTHENTICATION_SOURCES. Add it to log in with this account.
    initialEmail = "pgadmin@zx.dev";
    initialPasswordFile = config.age.secrets.pgadmin-password.path;
    settings = {
      # tailscale0 is trusted; the LAN port stays closed
      DEFAULT_SERVER = "0.0.0.0";
      AUTHENTICATION_SOURCES = ["oauth2"];
      OAUTH2_AUTO_CREATE_USER = false;
      OAUTH2_CONFIG = [
        {
          OAUTH2_NAME = "pocket-id";
          OAUTH2_DISPLAY_NAME = "Pocket ID";
          OAUTH2_CLIENT_ID = "pgadmin";
          OAUTH2_SERVER_METADATA_URL = "https://id.zx.dev/.well-known/openid-configuration";
          OAUTH2_SCOPE = "openid email profile";
        }
      ];
      # Nothing to encrypt: the server entry has no saved password
      MASTER_PASSWORD_REQUIRED = false;
    };
  };

  # The module renders settings as Python literals, so read the client
  # secret at runtime instead of putting it in the store.
  environment.etc."pgadmin/config_system.py".text = lib.mkAfter ''
    import os
    with open(os.path.join(os.environ["CREDENTIALS_DIRECTORY"], "oauth2_client_secret")) as f:
        OAUTH2_CONFIG[0]["OAUTH2_CLIENT_SECRET"] = f.read().strip()
  '';

  systemd.services.pgadmin = {
    environment.PGSERVICEFILE = serviceFile;
    serviceConfig.LoadCredential = [
      "oauth2_client_secret:${config.age.secrets.pgadmin-client-secret.path}"
    ];
    # After the module's setup-db. add-external-user prints "User already
    # exists." and exits 0 on later starts; --replace makes the server list
    # match servers.json on every start.
    preStart = lib.mkAfter ''
      ${cli} add-external-user ${user} --auth-source oauth2 --email ${user} --role User
      ${cli} load-servers ${servers} --user ${user} --auth-source oauth2 --replace
    '';
  };
}
