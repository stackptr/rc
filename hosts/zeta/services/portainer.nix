{
  config,
  pkgs,
  ...
}: {
  users.users.mu.extraGroups = ["docker"];
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers = {
    portainer = {
      image = "portainer/portainer-ee@sha256:3c805a3d01a2cadaaa15ede8b349d5a71358edcbbb0eb26c76881166319eae8";
      ports = [
        "8000:8000"
        "9443:9443"
      ];
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "portainer_data:/data"
      ];
      autoStart = true;
      extraOptions = [
        "--network=host"
      ];
    };
  };
}
