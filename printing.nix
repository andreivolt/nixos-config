{
  services = {
    printing = {
      enable = true;
      clientConf = ''
        <Printer default>
          UUID urn:uuid:3c151d9e-3d44-3a04-59f9-5cdfbb513438
          MakeModel DCP-L2520DW series
          DeviceURI ipp://192.168.1.15/ipp/print
        </Printer>
      '';
    };
  };

  home-manager.users.avo.home
    .sessionVariables.PRINTER = "default";
}
