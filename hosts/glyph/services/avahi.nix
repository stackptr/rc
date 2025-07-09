{
  config,
  pkgs,
  ...
}: {
  services.avahi = {
    enable = true;
    extraServiceFiles = {
      deviceinfo = ''
        <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">%h</name>
          <service>
            <type>_device-info._tcp</type>
            <port>0</port>
            <txt-record>model=Mac14,8</txt-record>
          </service>
        </service-group>
      '';
    };
  };
}
