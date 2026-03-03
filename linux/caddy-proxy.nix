{ config, ... }:
let
  caPem = ../secrets/local-ca.pem;
  caKeySecret = config.sops.secrets."local_ca/key_pem";
in {
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers.caddy-proxy = {
    image = "lucaslorentz/caddy-docker-proxy:2.9";
    ports = [ "443:443" "80:80" ];
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock"
      "${caPem}:/data/caddy/pki/authorities/local/intermediate.crt:ro"
      "${caKeySecret.path}:/data/caddy/pki/authorities/local/intermediate.key:ro"
    ];
  };
}
