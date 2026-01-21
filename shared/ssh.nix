# SSH configuration for NixOS machines (riva, watts, ampere)
#
# Keys stored in ~/drive/ssh-keys/:
#   hosts/<hostname>/ssh_host_ed25519_key[.pub]  -> copy to /persist/etc/ssh/
#   users/<hostname>/id_ed25519[.pub]            -> copy to ~/.ssh/
#
{ lib, ... }:

let
  keys = import ./ssh-keys.nix;
  allUserKeys = lib.attrValues keys.userKeys;

in {
  # Disable systemd-ssh-proxy - causes permissions errors (file owned by nobody)
  programs.ssh.systemd-ssh-proxy.enable = false;

  # Known hosts - trust all machines on the Tailnet
  programs.ssh.knownHosts = {
    riva = {
      hostNames = [ "riva" "riva.${keys.tailDomain}" ];
      publicKey = keys.hostKeys.riva;
    };
    watts = {
      hostNames = [ "watts" "watts.${keys.tailDomain}" ];
      publicKey = keys.hostKeys.watts;
    };
    ampere = {
      hostNames = [ "ampere" "ampere.${keys.tailDomain}" "hs.avolt.net" ];
      publicKey = keys.hostKeys.ampere;
    };
    phone = {
      hostNames = [ "phone" "phone.${keys.tailDomain}" ];
      publicKey = keys.hostKeys.phone;
    };
    mac = {
      hostNames = [ "mac" "mac.${keys.tailDomain}" ];
      publicKey = keys.hostKeys.mac;
    };
  };

  # Authorized keys - allow SSH from any device
  users.users.andrei.openssh.authorizedKeys.keys = allUserKeys;
  users.users.root.openssh.authorizedKeys.keys = allUserKeys;
}
