{ config, pkgs, ... }:

let
  script = pkgs.writeScript "wifi-control" ''
    #!/bin/bash

    find_ethernet_interface() {
      networksetup -listallhardwareports | awk '/Hardware Port: USB.*LAN/{getline; print $2}'
    }

    find_wifi_interface() {
      networksetup -listallhardwareports | awk '/Hardware Port: Wi-Fi/{getline; print $2}'
    }

    check_ethernet() {
      local ethernet_interface=$(find_ethernet_interface)
      [ -n "$ethernet_interface" ] &&
      ifconfig "$ethernet_interface" | grep -q "status: active" &&
      ping -c 1 8.8.8.8 &> /dev/null
    }

    wifi_on() {
      local wifi_interface=$(find_wifi_interface)
      [ -n "$wifi_interface" ] && networksetup -setairportpower "$wifi_interface" on
    }

    wifi_off() {
      local wifi_interface=$(find_wifi_interface)
      [ -n "$wifi_interface" ] && networksetup -setairportpower "$wifi_interface" off
    }

    while true; do
      if check_ethernet; then
        wifi_on
      else
        wifi_off
      fi
      sleep 30
    done
  '';
in
{
  launchd.user.agents.wifiControl = {
    path = [ config.environment.systemPath ];
    serviceConfig = {
      ProgramArguments = [ "${script}" ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/wifi-control.log";
      StandardErrorPath = "/tmp/wifi-control.error.log";
    };
  };
}
