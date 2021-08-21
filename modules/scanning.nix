{
  hardware.sane.enable = true;

  hardware.sane.brscan5.enable = true;

  hardware.sane.brscan5.netDevices = {
    brother = {
      model = "DCP-L2520DW";
      nodename = "BRW0080927AFBCE";
    };
  };

  networking.extraHosts = ''
    192.168.1.27 BRW0080927AFBCE
  '';

  users.users.avo.extraGroups = [ "scanner" ];
}
