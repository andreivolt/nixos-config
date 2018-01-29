{ config, pkgs, ... }:

{
  systemd.services.docker-gc = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    requires = [ "docker.service" ];
    postStop = "${pkgs.docker}/bin/docker rm -f docker-gc 2>/dev/null || true";
    script = ''
      ${pkgs.docker}/bin/docker rm -f docker-gc 2>/dev/null || true

      ${pkgs.docker}/bin/docker run --rm \
        --name docker-gc \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v /etc:/etc:ro \
        spotify/docker-gc
    '';
  };
}
