# LiveKit SFU server for low-latency screen sharing via WebRTC
{
  config,
  pkgs,
  lib,
  ...
}: let
  viewerPage = pkgs.writeTextDir "index.html" ''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width,initial-scale=1">
      <title>Screen Share</title>
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { background: #000; display: flex; align-items: center; justify-content: center; height: 100vh; }
        video { max-width: 100%; max-height: 100vh; object-fit: contain; }
        #status { color: #888; font-family: system-ui; position: absolute; }
      </style>
    </head>
    <body>
      <div id="status">Connecting...</div>
      <video id="video" autoplay playsinline muted></video>
      <script type="module">
        import { Room, RoomEvent } from "https://esm.sh/livekit-client@2.6.1";
        const S = document.getElementById("status");
        const roomId = location.pathname.replace(/\//g, "");
        if (!roomId) { S.textContent = "No room ID"; throw "no room"; }
        const res = await fetch("/t/" + roomId);
        if (!res.ok) { S.textContent = "Stream not found"; throw "no token"; }
        const token = (await res.text()).trim();
        const room = new Room();
        room.on(RoomEvent.TrackSubscribed, (track, pub, participant) => {
          S.textContent = "Track: " + track.kind + " from " + participant.identity;
          const el = track.attach();
          el.style.maxWidth = "100%";
          el.style.maxHeight = "100vh";
          el.style.objectFit = "contain";
          document.body.appendChild(el);
          S.style.display = "none";
        });
        room.on(RoomEvent.TrackUnsubscribed, (track) => {
          track.detach().forEach(el => el.remove());
        });
        room.on(RoomEvent.Disconnected, () => {
          S.textContent = "Disconnected";
          S.style.display = "";
        });
        await room.connect("wss://s.avolt.net", token);
        S.textContent = "Connected, waiting for stream...";
      </script>
    </body>
    </html>
  '';
in {
  services.livekit = {
    enable = true;
    keyFile = "/etc/livekit/keys";
    settings = {
      port = 7880;
      rtc = {
        tcp_port = 7881;
        port_range_start = 7882;
        port_range_end = 7883;
        use_external_ip = true;
      };
      logging.level = "info";
    };
  };

  # Token directory for viewer tokens (publisher writes here via SSH)
  systemd.tmpfiles.rules = [
    "d /var/lib/livekit-tokens 0755 andrei root -"
  ];

  # Nginx reverse proxy for LiveKit signaling + viewer page
  services.nginx.virtualHosts."s.avolt.net" = {
    forceSSL = true;
    enableACME = true;

    # Viewer tokens served from /t/<room-id>
    locations."/t/" = {
      alias = "/var/lib/livekit-tokens/";
    };

    # Any path with a room ID serves the viewer page
    locations."~ ^/[a-z0-9][a-z0-9][a-z0-9][a-z0-9][a-z0-9][a-z0-9][a-z0-9][a-z0-9]/?$" = {
      root = viewerPage;
      extraConfig = "try_files /index.html =404;";
    };

    # LiveKit signaling (HTTP + WebSocket)
    locations."/" = {
      proxyPass = "http://127.0.0.1:7880";
      proxyWebsockets = true;
    };
  };

  # Firewall: WebRTC ports (7880 accessed only by nginx locally)
  networking.firewall = {
    allowedTCPPorts = [7881];
    allowedUDPPorts = [7882 7883];
  };
}
