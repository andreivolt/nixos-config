{ config, lib, pkgs, ... }:

let
  email = (import ../../private/credentials.nix).email;
  accounts = email.accounts;
  primary = lib.findFirst (account: account.address == email.primary_address) null accounts;
  secondary = lib.findFirst (account: account.address == email.secondary_address) null accounts;

in {
  environment.systemPackages = with pkgs; [ notmuch ];

  home-manager.users.avo
    .home.sessionVariables.NOTMUCH_CONFIG = with config.home-manager.users.avo.xdg;
      "${configHome}/notmuch/config";

  # home-manager.users.avo
  #   .xdg.configFile."notmuch/config".text = lib.generators.toINI {} {
  home-manager.users.avo
    .home.file.".notmuch-config".text = lib.generators.toINI {} {
      user = {
        name = primary.from_name;
        primary_email = primary.address; other_email = secondary.address;
      };

      new = {
        tags = "unread;inbox;";
        ignore = "";
      };

      search = {
        exclude_tags = "deleted;spam;";
      };

      maildir = {
        synchronize_flags = true;
      };
    };
}
