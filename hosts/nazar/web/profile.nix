{
  config,
  pkgs,
  profile,
  ...
}: {
  containers.profile = {
    autoStart = true;
    config = {
      config,
      pkgs,
      ...
    }: let
      profileApp = profile.packages.${pkgs.system}.default;
    in {
      environment.systemPackages = [
        profileApp
      ];
      systemd.services.run-profile = {
        wantedBy = ["multi-user.target"];
        serviceConfig.ExecStart = "${profileApp}/bin/profile";
      };
      system.stateVersion = "24.05";
    };
  };
}
