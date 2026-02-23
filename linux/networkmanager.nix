{ pkgs, ... }:

{
  networking.networkmanager = {
    enable = true;

    wifi.macAddress = "random";
    ethernet.macAddress = "random";

    wifi.backend = "iwd";

    wifi.powersave = true;
  };

  users.users.andrei.extraGroups = ["networkmanager"];

  # Disable wifi when ethernet is connected, re-enable when disconnected
  networking.networkmanager.dispatcherScripts = [{
    type = "basic";
    source = pkgs.writeText "wifi-wired-exclusive" ''
      case "$2" in
        up)
          if [ "$(nmcli -g GENERAL.TYPE device show "$1")" = "ethernet" ]; then
            nmcli radio wifi off
          fi
          ;;
        down)
          if [ "$(nmcli -g GENERAL.TYPE device show "$1")" = "ethernet" ]; then
            nmcli radio wifi on
          fi
          ;;
      esac
    '';
  }];

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
