# Limit boot entries to prevent /boot from filling up
{
  boot.loader.systemd-boot.configurationLimit = 10;
}
