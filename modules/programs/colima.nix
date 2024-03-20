{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.colima;
  yamlFormat = pkgs.formats.yaml { };
  # https://github.com/abiosoft/colima/blob/main/embedded/defaults/colima.yaml
  defaultCfg = {
    cpu = 2;
    disk = 60;
    memory = 2;
    arch = "host";
    runtime = "docker";
    hostname = "null";
    kubernetes = {
      enabled = false;
      version = "v1.28.3+k3s2";
      k3Args = [ "--disable=traefik" ];
    };
    autoActivate = true;
    network = {
      address = false;
      dns = [];
      dnsHosts = {
        "host.docker.internal" = "host.lima.internal";
      };
    };
    forwardAgent = false;
    docker = {};
    vmType = "qemu";
    rosetta = false;
    mountType = "sshfs";
    mountInotify = false;
    cpuType = "host";
    provision = [];
    sshConfig = true;
    mounts = [];
    env = {};
  };
in {
  options.programs.colima = {
    enable = lib.mkEnableOption "Container runtimes on macOS ";
    settings = lib.mkOption {
      type = yamlFormat.type;
      default = defaultCfg;
      description =
        "Configuration written to {file}`~/.colima/default/colima.yaml`.";
      example = lib.literalExpression ''
        {
          cpu = 4;
          mounts = [
            {
              location = "~/project";
              writable = false;
            }
          ];
        };
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.colima pkgs.docker ];
    home.file."${config.home.homeDirectory}/.colima/default/colima.yaml".source = yamlFormat.generate "colima.yaml" (defaultCfg // cfg.settings);
  };
}
