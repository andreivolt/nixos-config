{ config, lib, pkgs, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;
  user = "andrei";
in {
  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    age.sshKeyPaths =
      if isDarwin then [ "/etc/ssh/ssh_host_ed25519_key" ]
      else [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

    secrets = {
      aws_config = { owner = user; };
      aws_credentials = { owner = user; };
      env = { owner = user; };
      glab_config = { owner = user; };
      linode_cli = { owner = user; };
      wrangler_config = { owner = user; };
      asciinema_install_id = { owner = user; };
      gdrive3_account = { owner = user; };
      gdrive3_secret = { owner = user; };
      oci_config = { owner = user; };
      oci_api_key_pem = { owner = user; };
    };
  };
}
