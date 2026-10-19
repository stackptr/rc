{config, ...}: {
  age.secrets.open-terminal-env = {
    file = ./../secrets/open-terminal-env.age;
    mode = "440";
  };

  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers.open-terminal = {
    image = "ghcr.io/open-webui/open-terminal:latest";
    ports = ["8000:8000"];
    volumes = ["open-terminal:/home/user"];
    environmentFiles = [config.age.secrets.open-terminal-env.path];
    environment = {
      OPEN_TERMINAL_MULTI_USER = "true";
    };
    extraOptions = ["--pull=newer"];
  };
}
