# SSH configuration for Tailnet machines (riva, watts, ampere, phone)
#
# Keys stored in ~/drive/ssh-keys/:
#   hosts/<hostname>/ssh_host_ed25519_key[.pub]  -> copy to /persist/etc/ssh/
#   users/<hostname>/id_ed25519[.pub]            -> copy to ~/.ssh/
#
{ lib, ... }:

let
  # Tailscale MagicDNS domain (from headscale config)
  tailDomain = "tail.avolt.net";

  # =============================================================================
  # HOST PUBLIC KEYS (for known_hosts)
  # =============================================================================
  hostKeys = {
    riva = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMLnH+F2bxmtxgUnNN9CeNBt6n43H3u2TmmPghgyFRN8";
    watts = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIM2FRYqJEu/63o4VROBZ9+v6YWjfCr+pxyObaaP4FGv";
    ampere = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEwA59wPqg8B8mJFsaSLsiMUCwtnZo4FbSEPAuC79MD/";
    phone = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEMhd9BSrNv42Dwegu9YIsj3VzDLMR8dAq+u1ZA/KYs9";
  };

  # =============================================================================
  # USER PUBLIC KEYS (for authorized_keys) - one key per device
  # =============================================================================
  userKeys = {
    riva = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH/pM8U6viCnzHTkz3SD4WJkYQzXr/mNi4sH6gJUge9R andrei@riva";
    watts = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAONf0j68+f/g6iATJFcPAqtpnu+WsF16pQJswg+evdv andrei@watts";
    ampere = "";
    phone = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJA4s03JG4C4b9/vd1qB2ZkGzVxuIYSL4cgVUzQ0khzX andrei@phone";
  };

  allUserKeys = lib.attrValues userKeys;

in {
  # Known hosts - trust all machines on the Tailnet
  programs.ssh.knownHosts = {
    riva = {
      hostNames = [ "riva" "riva.${tailDomain}" ];
      publicKey = hostKeys.riva;
    };
    watts = {
      hostNames = [ "watts" "watts.${tailDomain}" ];
      publicKey = hostKeys.watts;
    };
    ampere = {
      hostNames = [ "ampere" "ampere.${tailDomain}" "hs.avolt.net" ];
      publicKey = hostKeys.ampere;
    };
    phone = {
      hostNames = [ "phone" "phone.${tailDomain}" ];
      publicKey = hostKeys.phone;
    };
  };

  # Authorized keys - allow SSH from any device
  users.users.andrei.openssh.authorizedKeys.keys = allUserKeys;
  users.users.root.openssh.authorizedKeys.keys = allUserKeys;
}
