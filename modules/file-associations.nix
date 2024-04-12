{
  home-manager.users.andrei = { pkgs, config, ... }: rec {
    home.activation.duti = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.duti}/bin/duti ${pkgs.writeText "_" ''
        com.colliderli.iina aac all
        com.colliderli.iina mp4 all
        com.colliderli.iina mp3 all
        com.colliderli.iina webm all
        com.colliderli.iina mov all
        com.colliderli.iina ogg all

        dev.zed.Zed jsonl all

        com.mimestream.Mimestream mailto all

        com.sublimetext.4 md all
        com.sublimetext.4 txt all

        # com.chromium.Thorium public.url all
        # com.chromium.Thorium .html all
        org.mozilla.nightly public.url all
        org.mozilla.nightly .html all

        net.kovidgoyal.kitty public.shell-script shell
        net.kovidgoyal.kitty public.unix-executable shell
      ''}
   '';
  };
}
