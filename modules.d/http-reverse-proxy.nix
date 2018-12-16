{ pkgs, ... }:

{
  systemd.services.docker-nginx-proxy = with pkgs; {
    wantedBy = [ "multi-user.target" ];
    path = [ docker ];
    script = ''
      docker rm -f nginx-proxy 2>/dev/null || true
      docker network create nginx-proxy 2>/dev/null || true
      docker run \
        -p 80:80 \
        --name nginx-proxy \
        --network nginx-proxy \
        -v ${writeText "_" "proxy_read_timeout 999;"}:/etc/nginx/conf.d/custom.conf:ro \
        -v /etc/nginx/vhost.d \
        -v /var/run/docker.sock:/tmp/docker.sock:ro \
        jwilder/nginx-proxy''; };
}
