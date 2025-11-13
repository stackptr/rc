{
  config,
  pkgs,
  lib,
  utils,
  ...
}: let
  cfg = config.services.filebrowser-quantum;
  format = pkgs.formats.yaml {};
  inherit (lib) types;
  dataDir = "/var/lib/filebrowser-quantum";
in {
  options = {
    services.filebrowser-quantum = {
      enable = lib.mkEnableOption "FileBrowser Quantum";

      package = lib.mkPackageOption pkgs "filebrowser-quantum" {};

      user = lib.mkOption {
        type = types.str;
        default = "filebrowser-quantum";
        description = "User account under which FileBrowser Quantum runs.";
      };

      group = lib.mkOption {
        type = types.str;
        default = "filebrowser-quantum";
        description = "Group under which FileBrowser Quantum runs.";
      };

      openFirewall = lib.mkEnableOption "opening firewall ports for FileBrowser Quantum";

      settings = lib.mkOption {
        default = {};
        description = ''
          Settings for FileBrowser Quantum.
          Refer to <https://filebrowserquantum.com/en/docs/configuration/configuration-overview/> for all supported values.
        '';
        type = types.submodule {
          freeformType = format.type;

          options = {
            server = {
              port = lib.mkOption {
                default = 8080;
                description = ''
                  The port to listen on.
                '';
                type = types.port;
              };

              baseUrl = lib.mkOption {
                default = "/";
                description = ''
                  Base URL, primarily for reverse proxy.
                '';
                type = types.str;
              };

              database = lib.mkOption {
                default = "/var/lib/filebrowser-quantum/database.db";
                description = ''
                  The path to FileBrowser Quantum's database.
                '';
                type = types.path;
              };

              cacheDir = lib.mkOption {
                default = "/var/cache/filebrowser-quantum";
                description = ''
                  The directory where FileBrowser Quantum stores its cache.
                '';
                type = types.path;
                readOnly = true;
              };

              sources = lib.mkOption {
                description = ''
                  A list of file system locations accessible to users.
                '';
                type = types.listOf (types.submodule {
                  options = {
                    path = lib.mkOption {
                      description = ''
                        The filesystem path to the directory you want to serve.
                      '';
                      type = types.path;
                    };

                    name = lib.mkOption {
                      description = ''
                        Display name shown in the UI. If not specified, uses the base folder name from the path. Useful for providing user-friendly names like “Company Files” instead of just “documents”.
                      '';
                      type = types.nullOr types.str;
                    };

                    defaultEnabled = lib.mkOption {
                      default = false;
                      description = ''
                        Whether new users automatically get access to this source. Defaults to `false`. Set to `true` for shared sources that all users should see.
                      '';
                      type = types.bool;
                    };
                  };
                });
              };
            };
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd = {
      services.filebrowser-quantum = {
        after = ["network.target"];
        description = "FileBrowser Quantum";
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          ExecStart = let
            args = [
              (lib.getExe cfg.package)
              "-c"
              (format.generate "config.yaml" cfg.settings)
            ];
          in
            utils.escapeSystemdExecArgs args;

          StateDirectory = "filebrowser-quantum";
          CacheDirectory = "filebrowser-quantum";
          WorkingDirectory = dataDir;

          User = cfg.user;
          Group = cfg.group;
          UMask = "0077";

          NoNewPrivileges = true;
          PrivateDevices = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          MemoryDenyWriteExecute = true;
          LockPersonality = true;
          RestrictAddressFamilies = [
            "AF_UNIX"
            "AF_INET"
            "AF_INET6"
          ];
          DevicePolicy = "closed";
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
        };
      };

      tmpfiles.settings.filebrowser = {
        "${dataDir}".d = {
          inherit (cfg) user group;
          mode = "0700";
        };
        "${cfg.settings.server.cacheDir}".d = {
          inherit (cfg) user group;
          mode = "0700";
        };
      };
    };

    users.users = lib.mkIf (cfg.user == "filebrowser-quantum") {
      filebrowser-quantum = {
        inherit (cfg) group;
        isSystemUser = true;
      };
    };

    users.groups = lib.mkIf (cfg.group == "filebrowser-quantum") {
      filebrowser-quantum = {};
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [cfg.settings.server.port];
  };

  meta.maintainers = [
    lib.maintainers.stackptr
  ];
}
