{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./homebridge.nix
    ./znc.nix
  ];
  services.openssh.enable = true;
  services.tailscale = {
    enable = true;
    extraUpFlags = ["--ssh"];
  };
  programs.mosh.enable = true;
  programs.git.enable = true;
  programs.gnupg.agent.enable = true;
}
