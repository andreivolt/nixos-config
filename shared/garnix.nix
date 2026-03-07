{ config, ... }:
let
  p = config.sops.placeholder;
in {
  sops.secrets."garnix/token" = { sopsFile = ../secrets/secrets.yaml; owner = "andrei"; };

  sops.templates."garnix-netrc" = {
    content = ''
      machine cache.garnix.io
        login andreivolt
        password ${p."garnix/token"}
    '';
  };

  nix.settings = {
    substituters = [ "https://cache.garnix.io" ];
    trusted-public-keys = [ "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=" ];
    netrc-file = config.sops.templates."garnix-netrc".path;
    narinfo-cache-positive-ttl = 3600;
  };
}
