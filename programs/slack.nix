{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    weechat
    # https://github.com/wee-slack/wee-slack
  ];
}
