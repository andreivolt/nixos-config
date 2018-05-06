{ config, lib, pkgs, myName, myEmail, ... }:

let
  myName = "Andrei Vladescu-Olt"; myEmail = "andrei@avolt.net";
  makeEmacsDaemon = import ./make-emacs-daemon.nix;

in {
  environment.systemPackages = (with pkgs; [
    isync # https:++wiki.archlinux.org/index.php/Isync https:++gist.github.com/au/a271c09e8233f19ffb01da7f017c7269 https:++github.com/kzar/davemail
    mailutils
    msmtp
    notmuch
    procmail
  ]);

  systemd.user.services.mailEmacsDaemon = makeEmacsDaemon { inherit config pkgs; name = "mail"; };

  services.offlineimap.enable = true;

  home-manager.users.avo
    .home.file.".msmtprc".text =
      let email = (import ./credentials.nix).email;
      in ''
        defaults
        auth            on
        tls             on
        tls_trust_file  /etc/ssl/certs/ca-certificates.crt

        ${lib.concatStrings (map (account: ''
          account  ${if account ? name then account.name else account.email}
          host     ${if account ? type && account.type == "gmail" then "smtp.gmail.com" else account.host}
          port     ${if account ? type && account.type == "gmail" then "587" else account.port}
          user     ${if account ? type && account.type == "gmail" then account.email else account.user}
          password ${account.password}
          from     ${if account ? type && account.type == "gmail" then account.email else account.from}
        '') email.accounts)}

        account default: ${email.default}
      '';

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
        remoteuser = myEmail; remotepass = (import ./credentials.nix).avolt_google_password;
        sslcacertfile = "/etc/ssl/certs/ca-certificates.crt";
        nametrans = "lambda folder: {'[Gmail]/All Mail': 'archive',}.get(folder, folder)";
        folderfilter = "lambda folder: folder == '[Gmail]/All Mail'";
        realdelete = "yes";
        synclabels = "yes";
        keepalive = 60;
        holdconnectionopen = "yes";
      };
    });

  home-manager.users.avo
    .home.sessionVariables.NOTMUCH_CONFIG = with config.home-manager.users.avo.xdg;
      "${configHome}/notmuch/config";

  home-manager.users.avo
    .xdg.configFile."notmuch/config".text = lib.generators.toINI {} {
      user = {
        name = myName;
        primary_email = myEmail; other_email = "andrei.volt@gmail.com";
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

  environment.etc."mailcap".text = let
    plaintextify = "${pkgs.avo-scripts}/bin/plaintextify < %s; copiousoutput";
    libreoffice = "${pkgs.libreoffice-fresh}/bin/libreoffice %s";
  in ''
    application/doc;
    application/msword;                                                        ${plaintextify}
    application/pdf;                                                           ${pkgs.zathura}/bin/zathura %s pdf
    application/vnd.ms-powerpoint;                                             ${libreoffice}
    application/vnd.ms-powerpoint;                                             ${plaintextify}
    application/vnd.openxmlformats-officedocument.presentationml.presentation; ${libreoffice}
    application/vnd.openxmlformats-officedocument.presentationml.presentation; ${plaintextify}
    application/vnd.openxmlformats-officedocument.presentationml.slideshow;    ${libreoffice}
    application/vnd.openxmlformats-officedocument.presentationml.slideshow;    ${plaintextify}
    application/vnd.openxmlformats-officedocument.spreadsheetmleet;            ${plaintextify}
    application/vnd.openxmlformats-officedocument.wordprocessingml.document;   ${plaintextify}
    image;                                                                     ${pkgs.sxiv}/bin/sxiv %s
    text/html;                                                                 ${pkgs.qutebrowser}/bin/qutebrowser-open;
    text/html;                                                                 ${pkgs.w3m}/bin/w3m -o display_link=true -o display_link_number=true -dump -I %{charset} -cols 72 -T text/html %s; nametemplate=%s.html; copiousoutput
  '';

  environment.etc."mailrc".text = ''
    set sendmail=${pkgs.msmtp}/bin/msmtp"
  '';

  home-manager.users.avo
    .programs.zsh.shellAliases.msmtp = with config.home-manager.users.avo;
      "${xdg.cacheHome}/mstmp/msmtprc";
}
