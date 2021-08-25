{
  networking.networkmanager.enable = true;

  # randomize-mac-addresses
  networking.networkmanager.wifi.macAddress = "random";
  networking.networkmanager.ethernet.macAddress = "random";

  # TODO: doesn't come back after powersave
  # networking.networkmanager.wifi.powersave = true;

  users.users.avo.extraGroups = [ "networkmanager" ];
}
