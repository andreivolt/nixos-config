{ config, pkgs, inputs, ... }:
let
  caPem = ../secrets/local-ca.pem;
  caKeySecret = config.sops.secrets."local_ca/key_pem";
in {
  sops.secrets."local_ca/key_pem" = {
    owner = "andrei";
  };

  security.pki.certificateFiles = [ caPem ];

  environment.systemPackages = [ pkgs.mkcert ];

  home-manager.sharedModules = [{
    home.activation.setupLocalCA = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p $HOME/.local/share/mkcert
      ln -sf ${caPem} $HOME/.local/share/mkcert/rootCA.pem
      ln -sf ${caKeySecret.path} $HOME/.local/share/mkcert/rootCA-key.pem
    '';
  }];
}
