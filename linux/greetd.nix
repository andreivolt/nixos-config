{ pkgs, inputs, ... }:

let
  hyprland = inputs.hyprland.packages.${pkgs.system}.hyprland;
in {
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd 'uwsm start ${hyprland}/bin/hyprland'";
        user = "greeter";
      };
    };
  };

  # Make wayland-sessions available
  environment.etc."greetd/environments".text = ''
    uwsm start ${hyprland}/bin/hyprland
  '';
}
