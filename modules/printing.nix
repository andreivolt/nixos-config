{
  environment.variables.PRINTER = "_";
  services.printing.enable = true;
  services.printing.clientConf = lib.mkAfter ''
  <Printer _>
  UUID urn:uuid:3c151d9e-3d44-3a04-59f9-5cdfbb513438
  MakeModel DCP-L2520DW series
  DeviceURI ipp://192.168.1.27/ipp/print
  </Printer>
  '';
}
