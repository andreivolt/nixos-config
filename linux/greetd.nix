{ pkgs, ... }:

{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd 'uwsm start hyprland'";
        user = "greeter";
      };
    };
  };

  # Make wayland-sessions available
  environment.etc."greetd/environments".text = ''
    uwsm start hyprland
  '';
}
