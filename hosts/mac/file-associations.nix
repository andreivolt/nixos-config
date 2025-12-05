{
  home-manager.users.andrei = {
    pkgs,
    config,
    ...
  }: {
    home.activation.duti = config.lib.dag.entryAfter ["writeBoundary"] ''
      ${pkgs.duti}/bin/duti ${pkgs.writeText "_" ''
        com.colliderli.iina aac all
        com.colliderli.iina flac all
        com.colliderli.iina mov all
        com.colliderli.iina mp3 all
        com.colliderli.iina mp4 all
        com.colliderli.iina ogg all
        com.colliderli.iina webm all

        com.mimestream.Mimestream mailto all

        com.sublimetext.4 md all
        com.sublimetext.4 txt all

        org.mozilla.nightly public.url all

        com.mitchellh.ghostty public.shell-script shell
        com.mitchellh.ghostty public.unix-executable shell

        org.mozilla.nightly .xpi all
      ''}
    '';
  };
}
