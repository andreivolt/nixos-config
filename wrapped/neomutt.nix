self: super: with super; {

neomutt =
  let conf = ''
    auto_view text/html
    set abort_nosubject
    set collapse_all
    set date_format = "%a %m-%d %R"
    set edit_headers
    set empty_subject = ""
    set fast_reply = yes
    set folder = ~/mail
    set header_cache = ~/.cache/mutt
    set help = no
    set include
    set index_format = "%Z %D  %-25.25L %?X? ☐&  ?  %s %?g?[%g]& ?"
    set mbox_type = Maildir
    set nomark_old
    set postponed = "+/Inbox.Drafts"
    set record = "+/Sent Items"
    set reverse_name
    set sendmail = msmtp
    set sort = reverse-last-date-sent
    set spoolfile = "+/archive"
    set status_format = ""
    set ts_enabled
    set ts_status_format = "NeoMutt %?n? [%n NEW]?"
    unset check_new
    unset collapse_unread
    unset reply_self

    color attach_headers yellow default ".*"

    color normal white default

    color index_author yellow default ".*"
    color status color0 color0
    color indicator default color15

    color header color11 default .*
    color quoted color8 color15
    color quoted1 color7 color15
    color quoted2 color8 color15
    color quoted3 color7 color15
    color quoted4 color8 color15
    color quoted5 color7 color15
    color quoted6 color8 color15
    color quoted7 color7 color15
    color quoted8 color8 color15
    color quoted9 color7 color15

    # moving around
    bind attach,browser,index       g   noop
    bind attach,browser,index       gg  first-entry
    bind attach,browser,index       G   last-entry
    bind pager                      g  noop
    bind pager                      gg  top
    bind pager                      G   bottom
    bind pager                      k   previous-line
    bind pager                      j   next-line

    bind index R sync-mailbox

    # scrolling
    bind attach,browser,pager,index \CF next-page
    bind attach,browser,pager,index \CB previous-page
    bind attach,browser,pager,index \Cu half-up
    bind attach,browser,pager,index \Cd half-down
    bind browser,pager              \Ce next-line
    bind browser,pager              \Cy previous-line
    bind index                      \Ce next-line
    bind index                      \Cy previous-line

    bind pager,index                d   noop
    bind pager,index                dd  delete-message

    # mail & reply
    bind index                      r group-reply

    # threads
    bind browser,pager,index        N   search-opposite
    bind pager,index                dT  delete-thread
    bind pager,index                dt  delete-subthread
    bind pager,index                gt  next-thread
    bind pager,index                gT  previous-thread
    bind index                      za  collapse-thread
    bind index                      zA  collapse-all'';
  in let _ = ''
    wrapProgram $out/bin/neomutt \
      --add-flags '-F ${writeText "_" conf}' '';
  in hiPrio (stdenv.lib.overrideDerivation neomutt (attrs: {
    buildInputs = attrs.buildInputs or [] ++ [ makeWrapper ];
    postInstall = attrs.postInstall or "" + _; }));

}
