{ pkgs, inputs, ... }:

let
  hyprland = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
in {
  services.greetd = {
    enable = true;
    # vt option removed - now fixed to VT1 in nixos-unstable
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd 'uwsm start ${hyprland}/bin/hyprland'";
        user = "greeter";
      };
    };
  };

  # Make wayland-sessions available
  environment.etc."greetd/environments".text = ''
    uwsm start ${hyprland}/bin/hyprland
  '';
}
