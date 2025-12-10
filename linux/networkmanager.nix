{
  networking.networkmanager = {
    enable = true;

    wifi.macAddress = "random";
    ethernet.macAddress = "random";

    wifi.backend = "iwd";

    wifi.powersave = true;
  };

  users.users.andrei.extraGroups = ["networkmanager"];

  # Make WiFi connections available system-wide (before login)
  # This removes user-specific permissions from all WiFi connections
  systemd.services.NetworkManager.preStart = ''
    for file in /etc/NetworkManager/system-connections/*; do
      if [ -f "$file" ]; then
        sed -i '/^permissions=/d' "$file"
      fi
    done
  '';
}
