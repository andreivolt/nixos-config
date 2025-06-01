{
  networking.networkmanager = {
    enable = true;

    wifi.macAddress = "random";
    ethernet.macAddress = "random";

    wifi.backend = "iwd";

    wifi.powersave = true; # TODO: doesn't come back after powersave
  };

  users.users.andrei.extraGroups = ["networkmanager"];
}
