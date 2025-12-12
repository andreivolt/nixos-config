{ config, lib, pkgs, inputs, ... }: {
  home-manager.sharedModules = [{
    home.activation.linkSopsSecrets = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
      # AWS
      mkdir -p $HOME/.aws
      ln -sf /run/secrets/aws_config $HOME/.aws/config
      ln -sf /run/secrets/aws_credentials $HOME/.aws/credentials

      # Env (source from shell: source ~/.config/env)
      mkdir -p $HOME/.config
      ln -sf /run/secrets/env $HOME/.config/env

      # GitLab CLI
      mkdir -p $HOME/.config/glab-cli
      ln -sf /run/secrets/glab_config $HOME/.config/glab-cli/config.yml

      # Linode CLI
      ln -sf /run/secrets/linode_cli $HOME/.config/linode-cli

      # Cloudflare Wrangler
      mkdir -p $HOME/.config/.wrangler/config
      ln -sf /run/secrets/wrangler_config $HOME/.config/.wrangler/config/default.toml

      # Asciinema
      mkdir -p $HOME/.config/asciinema
      ln -sf /run/secrets/asciinema_install_id $HOME/.config/asciinema/install-id

      # Google Drive (gdrive3) - static creds only, not tokens
      mkdir -p $HOME/.config/gdrive3/andrei.volt@gmail.com
      ln -sf /run/secrets/gdrive3_account $HOME/.config/gdrive3/account.json
      ln -sf /run/secrets/gdrive3_secret $HOME/.config/gdrive3/andrei.volt@gmail.com/secret.json

      # OCI
      mkdir -p $HOME/.oci
      ln -sf /run/secrets/oci_config $HOME/.oci/config
      ln -sf /run/secrets/oci_api_key_pem $HOME/.oci/oci_api_key.pem
      # Generate public key from private key
      ${pkgs.openssl}/bin/openssl rsa -pubout -in /run/secrets/oci_api_key_pem -out $HOME/.oci/oci_api_key_public.pem 2>/dev/null || true
    '';
  }];
}
