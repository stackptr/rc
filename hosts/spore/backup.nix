{lib, ...}: {
  rc.backup = {
    enable = lib.mkForce true;
    paths = [];
  };
}
