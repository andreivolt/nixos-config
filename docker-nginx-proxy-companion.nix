{ config, pkgs, ... }:

{
  systemd.services.docker-nginx-proxy-companion = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    requires = [ "docker.service" ];
    script = ''
      ${pkgs.docker}/bin/docker run --rm \
        --name nginx-proxy-companion \
        -v /var/lib/docker-nginx-proxy-certs:/etc/nginx/certs:rw \
        -v /var/run/docker.sock:/var/run/docker.sock:ro \
        --volumes-from nginx-proxy \
        jrcs/letsencrypt-nginx-proxy-companion
    '';
    preStop = "${pkgs.docker}/bin/docker rm -f nginx-proxy-companion";
  };
}
