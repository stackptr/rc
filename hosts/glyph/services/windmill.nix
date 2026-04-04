{
  config,
  pkgs,
  ...
}: {
  services.windmill = {
    enable = true;
    serverPort = 8100;
    baseUrl = "https://windmill.zx.dev";
    database.createLocally = true;
  };

  # The NixOS module's initdb omits table grants from the upstream
  # init-db-as-superuser.sql, causing permission errors at runtime.
  # Patch the initdb service to include them.
  systemd.services.windmill-initdb.script = let
    cfg = config.services.windmill;
    psql = "${config.services.postgresql.package}/bin/psql";
  in ''
    ${psql} -tA <<"EOF"
      DO $$
      BEGIN
          IF NOT EXISTS (
              SELECT FROM pg_catalog.pg_roles
              WHERE rolname = 'windmill_user'
          ) THEN
              CREATE ROLE windmill_user;
          END IF;
          IF NOT EXISTS (
              SELECT FROM pg_catalog.pg_roles
              WHERE rolname = 'windmill_admin'
          ) THEN
            CREATE ROLE windmill_admin WITH BYPASSRLS;
            GRANT windmill_user TO windmill_admin;
          END IF;
          GRANT windmill_admin TO ${cfg.database.user};
      END
      $$;

      GRANT ALL PRIVILEGES ON DATABASE ${cfg.database.name} TO windmill_user;
      GRANT ALL ON ALL TABLES IN SCHEMA public TO windmill_user;
      GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO windmill_user;
      ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO windmill_user;
      ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO windmill_user;
    EOF
  '';
}
