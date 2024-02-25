{
  home-manager.users.andrei = { pkgs, ... }: {
    home.file.".pydistutils.cfg".text = ''
      [build_ext]
      include_dirs=${pkgs.portaudio}/include/
      library_dirs=${pkgs.portaudio}/lib/
    '';
  };
}
