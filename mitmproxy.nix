{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ mitmproxy ];

  home-manager.users.avo
    .xdg.configFile."mitmproxy/config.yaml".text = with config.home-manager.users.avo; lib.generators.toYAML {} {
      CA_DIR = "${xdg.configHome}/mitmproxy/certs";
    };

  home-manager.users.avo
    .programs.zsh.shellAliases.mitmproxy = with config.home-manager.users.avo;
      "${pkgs.mitmproxy}/bin/mitmproxy --conf ${xdg.configHome}/mitmproxy/config.yaml";
}
