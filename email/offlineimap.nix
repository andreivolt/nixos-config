{ config, lib, pkgs, ... }:

let
  email = lib.findFirst (account: account.address == "andrei@avolt.net") null (import ../credentials.nix).email.accounts;

in {
  services.offlineimap.enable = true;

  home-manager.users.avo
    .xdg.configFile."offlineimap/config".text = lib.generators.toINI {} (let account = "avolt.net"; in {
      general = {
        accounts = account;
        fsync = false;
        maxconnections = 10;
        autorefresh = "0.5";
        quick = 10;
        metadata = "${config.home-manager.users.avo.xdg.cacheHome}/offlineimap";
      };

      "Account ${account}" = {
        localrepository = "${account}_local"; remoterepository = "${account}_remote";
        postsynchook = "${pkgs.notmuch}/bin/notmuch new";
        realdelete = "yes";
      };

      "Repository ${account}_local" = {
        localfolders = "~/mail/${account}";
        type = "Maildir";
        nametrans = "lambda folder: folder == 'INBOX' and 'INBOX' or ('INBOX.' + folder)";
      };

      "Repository ${account}_remote" = {
        type = "Gmail";
        remoteuser = email.address; remotepass = email.password;
        sslcacertfile = "/etc/ssl/certs/ca-certificates.crt";
        nametrans = "lambda folder: {'[Gmail]/All Mail': 'archive',}.get(folder, folder)";
        folderfilter = "lambda folder: folder == '[Gmail]/All Mail'";
        realdelete = "yes";
        synclabels = "yes";
        keepalive = 60;
        holdconnectionopen = "yes";
      };
    });
}
