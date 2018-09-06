{ config, lib, pkgs, ... }:

let
  mitmproxy-config = pkgs.writeText "mitmproxy-config" lib.generators.toYAML {} {
    CA_DIR = "~/.config/mitmproxy/certs";
  };

{
  environment.systemPackages = with pkgs; [ mitmproxy ];

  programs.zsh.interactiveShellInit = lib.mkAfter "
    alias mitmproxy='${pkgs.mitmproxy}/bin/mitmproxy --conf ${mitmproxy-config}'";
}
