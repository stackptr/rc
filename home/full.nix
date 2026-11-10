# Everything a lightweight host (zeta, spore) leaves out; lib/hosts.nix
# imports it on the rest.
{
  rc = {
    development = {
      containers.enable = true;
      javascript.enable = true;
    };
    entire.enable = true;
    jujutsu.enable = true;
    utilities = {
      file.enable = true;
      media.enable = true;
    };
  };
}
