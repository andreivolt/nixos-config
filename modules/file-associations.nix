{
  home-manager.users.andrei = { pkgs, ... }: rec {
    home.file.".duti" = {
      text = ''
        com.colliderli.iina aac all
        com.colliderli.iina mp4 all
        com.colliderli.iina mp3 all
        com.colliderli.iina webm all
        com.mimestream.Mimestream mailto
        com.sublimetext.4 md all
        com.sublimetext.4 txt all
        net.kovidgoyal.kitty public.shell-script shell
        net.kovidgoyal.kitty public.unix-executable shell
      '';
      onChange = "${pkgs.duti}/bin/duti ~/.duti";
    };
  };
}
