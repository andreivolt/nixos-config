{
  hardware.sane.enable = true;

  hardware.sane.brscan5 = {
    enable = true;

    netDevices = {
      brother = {
        model = "DCP-L2520DW";
        nodename = "BRW0080927AFBCE";
      };
    };
  };

  networking.extraHosts = "192.168.1.174 BRW0080927AFBCE";

  users.users.andrei.extraGroups = ["scanner"];
}
