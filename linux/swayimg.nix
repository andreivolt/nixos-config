# Swayimg image viewer configuration
{ ... }: {
  xdg.configFile."swayimg/config".text = ''
    [general]
    size = image
    overlay = no

    [viewer]
    scale = optimal

    [font]
    name = Roboto
    size = 14

    [info]
    show = no
  '';
}
