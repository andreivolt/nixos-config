let
  font = "Ubuntu";
in
{
  home-manager.users.andrei.gtk = {
    enable = true;
    theme.name = "Breeze-Dark";
    # font.name = "${font} 10";
  };
}
