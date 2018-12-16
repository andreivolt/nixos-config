{ lib, ... }:

with lib;

{
  services.printing.enable = true;

  services.printing.clientConf = mkAfter ''
    <Printer brother>
      UUID urn:uuid:3c151d9e-3d44-3a04-59f9-5cdfbb513438
      MakeModel DCP-L2520DW series
      DeviceURI ipp://192.168.1.15/ipp/print
    </Printer>
  '';

  environment.variables.PRINTER = "brother";
}
