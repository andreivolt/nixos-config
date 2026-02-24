{ config, lib, pkgs, inputs, ... }:
let
  awsConfig = config.sops.templates."aws-config".path;
  awsCredentials = config.sops.templates."aws-credentials".path;
  linodeCli = config.sops.templates."linode-cli".path;
  gdrive3Secret = config.sops.templates."gdrive3-secret".path;
  sessionEnv = config.sops.templates."session-env".path;
in
{
  home-manager.sharedModules = [{
    home.activation.linkSopsSecrets = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p $HOME/.aws
      ln -sf ${awsConfig} $HOME/.aws/config
      ln -sf ${awsCredentials} $HOME/.aws/credentials

      mkdir -p $HOME/.config
      ln -sf ${linodeCli} $HOME/.config/linode-cli

      mkdir -p $HOME/.config/gdrive3/andrei.volt@gmail.com
      ln -sf ${gdrive3Secret} $HOME/.config/gdrive3/andrei.volt@gmail.com/secret.json

      mkdir -p $HOME/.config/environment.d
      ln -sf ${sessionEnv} $HOME/.config/environment.d/sops.conf

      mkdir -p $HOME/.oci
      ln -sf /run/secrets/oci_api_key_pem $HOME/.oci/oci_api_key.pem
      ${pkgs.openssl}/bin/openssl rsa -pubout -in /run/secrets/oci_api_key_pem -out $HOME/.oci/oci_api_key_public.pem 2>/dev/null || true
    '';

    home.file.".oci/config".text = lib.generators.toINI {} {
      DEFAULT = {
        user = "ocid1.user.oc1..aaaaaaaazqf7w6jdk7632rqqbpgo6odwcg4olgwasedu3urjztd4vsxnbisq";
        fingerprint = "5f:e5:b5:1f:47:a6:e8:2e:c7:42:0f:c9:9d:14:df:45";
        key_file = "~/.oci/oci_api_key.pem";
        tenancy = "ocid1.tenancy.oc1..aaaaaaaaxhpshf4vvz7slwxlpevnxbm3hzrcex7of6aima6uachydzb4rvva";
        region = "eu-amsterdam-1";
      };
    };
  }];
}
