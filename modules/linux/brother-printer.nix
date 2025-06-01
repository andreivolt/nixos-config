{pkgs, ...}: {
  services.printing.enable = true;

  programs.system-config-printer.enable = true;
  # services.system-config-printer.enable = true;

  services.printing.drivers = [pkgs.brlaser];

  services.printing.webInterface = false;

  hardware.printers.ensurePrinters = [
    {
      name = "brother";
      deviceUri = "dnssd://Brother%20DCP-L2520DW%20series._ipp._tcp.local/?uuid=e3248000-80ce-11db-8000-a86bada1eb19";
      model = "drv:///brlaser.drv/brl2520d.ppd";
      # ppdOptions = {
      #   PageSize = "A4";
      #   Duplex = "DuplexNoTumble";
      # };
    }
  ];
  hardware.printers.ensureDefaultPrinter = "brother";

  environment.etc."/papersize".text = "a4";
  # environment.variables.PRINTER = "_";
  # services.printing.clientConf = lib.mkAfter ''
  #   <Printer _>
  #     UUID urn:uuid:3c151d9e-3d44-3a04-59f9-5cdfbb513438
  #     MakeModel DCP-L2520DW series
  #     DeviceURI ipp://192.168.1.27/ipp/print
  #   </Printer>
  # '';

  users.users.andrei.extraGroups = ["lp"];
}
