{ config, pkgs, lib, ... }:

{
  # Since /home is persistent, we don't need to symlink user directories from /persist
  # Everything in /home/andrei is already preserved across reboots

  # No user-specific persistence configuration needed
  # environment.persistence."/persist".users.andrei = { };

  # Ensure the password file directory exists
  systemd.tmpfiles.rules = [
    "d /persist/passwords 0700 root root -"
  ];
}
