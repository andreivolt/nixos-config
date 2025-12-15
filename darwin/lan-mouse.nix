{ config, pkgs, lib, ... }:

let
  # Certificate fingerprints for each host (sha256 of lan-mouse.pem)
  # Must be lowercase - lan-mouse's generate_fingerprint() outputs lowercase hex
  fingerprints = {
    mac = "ca:34:50:7f:1b:43:20:c8:5a:7b:3e:36:e5:6e:ff:99:6b:43:c0:a5:8c:da:70:fd:d3:9e:b4:57:0a:60:3e:a7";
    watts = "ec:5f:c5:b1:cb:69:0a:18:ba:3a:fd:ac:c2:03:58:e2:4b:24:02:09:54:f6:cf:74:ff:c1:9f:58:56:e8:99:06";
  };

  # Mac connects to watts (riva is the same machine as mac, just Asahi Linux)
  configToml = pkgs.writeText "lan-mouse-config.toml" ''
    port = 4242

    [[clients]]
    hostname = "watts"
    ips = ["100.64.0.3"]
    port = 4242
    position = "right"
    activate_on_startup = true

    [authorized_fingerprints]
    "${fingerprints.watts}" = "watts"
  '';
in {
  environment.systemPackages = [ pkgs.lan-mouse ];

  home-manager.users.andrei = { config, pkgs, ... }: {
    launchd.agents.lan-mouse = {
      enable = true;
      config = {
        Label = "com.github.feschber.lan-mouse";
        ProgramArguments = [
          "${pkgs.lan-mouse}/bin/lan-mouse"
          "--config" "${configToml}"
          "--cert-path" "${config.home.homeDirectory}/.config/lan-mouse/lan-mouse.pem"
          "daemon"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/tmp/lan-mouse.log";
        StandardErrorPath = "/tmp/lan-mouse.err";
      };
    };
  };
}
