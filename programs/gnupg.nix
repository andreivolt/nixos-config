{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ gnupg ];

  environment.variables.GNUPGHOME = "~/.config/gnupg";
}
