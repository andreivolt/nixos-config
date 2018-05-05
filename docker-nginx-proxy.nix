{ config, pkgs, ... }:

{
  systemd.services.docker-nginx-proxy = with pkgs; {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    requires = [ "docker.service" ];
    script = ''
      ${docker}/bin/docker rm -f nginx-proxy 2>/dev/null || true

      ${docker}/bin/docker network create nginx-proxy 2>/dev/null || true

      ${docker}/bin/docker run \
        --rm \
        -p 80:80 -p 443:443 \
        --name nginx-proxy \
        --network nginx-proxy \
        -v /var/lib/docker-nginx-proxy.vhost.d:/etc/nginx/vhost.d:ro \
        -v /var/lib/docker-nginx-proxy.certs:/etc/nginx/certs:ro \
        -v /etc/nginx/vhost.d \
        -v /usr/share/nginx/html \
        -v /var/run/docker.sock:/tmp/docker.sock:ro \
        --label com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy=true \
        jwilder/nginx-proxy
    '';
    preStop = "${docker}/bin/docker rm -f nginx-proxy";
  };
}
