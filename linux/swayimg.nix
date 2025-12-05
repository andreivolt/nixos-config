{
  home-manager.sharedModules = [
    {
      xdg.configFile."swayimg/config".text = ''
        [general]
        size = image
        overlay = no

        [viewer]
        scale = optimal

        [font]
        name = Tahoma
        size = 14

        [info]
        show = no
      '';
    }
  ];
}
