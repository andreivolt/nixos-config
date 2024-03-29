{ lib, config, ... }:

let authtoken = builtins.getEnv "NGROK_TOKEN";
in {
  home-manager.users.andrei = { pkgs, ... }: {
    home.packages = with pkgs; [ ngrok ];

    home.file.".ngrok2/ngrok.yml".text = lib.generators.toYAML { } { inherit authtoken; version = "2"; };
  };
}
