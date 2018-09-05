{ config, lib, pkgs, ... }:

let
  email = (import ../../credentials.nix).email;
  accounts = email.accounts;
  primary = lib.findFirst (account: account.address == email.primary_address) null accounts;
  secondary = lib.findFirst (account: account.address == email.secondary_address) null accounts;
  notmuch-config = pkgs.writeText "notmuch-config" (lib.generators.toINI {} {
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
  });

in {
  environment.systemPackages = with pkgs; [ notmuch ];

  environment.variables.NOTMUCH_CONFIG = "${notmuch-config}";
}
