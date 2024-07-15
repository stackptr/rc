{
  config,
  pkgs,
  ...
}: {
  users.users.mu.extraGroups = ["docker"];
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers = {
    filebrowser = {
      image = "filebrowser/filebrowser@sha256:862a8f4f4829cb2747ced869aea8593204bbc718c92f0f11c97e7b669a54b53d";
      ports = [
        "8080:80"
      ];
      volumes = [
        "/mnt/media:/srv"
        "/mnt/docker/filebrowser.db:/database.db"
      ];
      user = "1001:100";
      autoStart = true;
    };
  };
}
