{ config, pkgs, ... }:

{
  services.autossh.sessions = [
    {
      name = "megawatts";
      user = "avo";
      extraArguments = "-o ControlMaster=no -N -D 19999 avo@megawatts.avolt.net";
    }
  ];
}
