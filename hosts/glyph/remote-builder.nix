# Send aarch64-linux builds (zeta's, mostly) to Stroma's linux-builder VM
# (hosts/Stroma/linux-builder.nix) instead of emulating them here. If Stroma
# can't be reached, Nix falls back to building locally through binfmt.
{
  config,
  keys,
  ...
}: let
  stroma = "stroma.note-iwato.ts.net";
in {
  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = stroma;
        protocol = "ssh-ng";
        sshUser = "corey";
        sshKey = config.age.secrets.ssh-client-key.path;
        systems = ["aarch64-linux"];
        maxJobs = 16;
        speedFactor = 10;
        supportedFeatures = ["kvm" "benchmark" "big-parallel"];
      }
    ];
    # Stroma fetches what it can from the caches itself instead of glyph
    # uploading every input.
    settings.builders-use-substitutes = true;
  };

  programs.ssh = {
    knownHosts.stroma = {
      hostNames = [stroma];
      publicKey = keys.Stroma;
    };
    # Fail fast to local builds when Stroma is asleep or off the tailnet
    extraConfig = ''
      Host ${stroma}
        ConnectTimeout 5
    '';
  };
}
