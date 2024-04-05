{ lib, config, ... }:

let authtoken = builtins.getEnv "NGROK_TOKEN";
in {
  home-manager.users.andrei = { pkgs, ... }: {
    home.packages = with pkgs; [ ngrok ];

    xdg.configFile."ngrok/ngrok.yml".text = lib.generators.toYAML { } { inherit authtoken; version = "2"; };
  };
}
