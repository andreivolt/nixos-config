{ pkgs, ... }:

{
  systemd.services.swaylock = {
    before = [ "sleep.target" ];
    serviceConfig.Type = "forking";
    serviceConfig.User = "avo";
    serviceConfig.ExecStartPost = "${pkgs.coreutils}/bin/sleep 1";
    environment.WAYLAND_DISPLAY = "wayland-1";
    environment.XDG_RUNTIME_DIR = "/run/user/1000";
    wantedBy = [ "sleep.target" ];
    serviceConfig.ExecStart = ''
      ${pkgs.swaylock}/bin/swaylock \
        --indicator-thickness 100 \
        --indicator-radius 50 \
        -c 000000 \
        --inside-color 006400ff \
        --ring-color 006400ff \
        --line-color 006400ff \
        --key-hl-color 00ff00ff \
        --bs-hl-color ff0000ff \
        --separator-color 006400ff \
        --inside-ver-color 00ff00ff \
        --inside-wrong-color ff0000ff \
        --ring-ver-color 006400ff \
        --ring-wrong-color ff0000ff \
        --text-color 00000000 \
        --text-ver-color 00000000 \
        --text-wrong-color 00000000 \
        --layout-bg-color 00000000 \
        --layout-border-color 00000000 \
        --layout-text-color 00000000
    '';
  };

  # playerctl -a pause
  # home-manager.users.andrei.systemd.user.services.swaylock = {
  #   Service = {
  #     ExecStart = "${pkgs.swaylock}/bin/swaylock -f -c 000000";
  #     ExecStartPost = "${pkgs.coreutils}/bin/sleep 1";
  #     Type = "forking";
  #     User = "avo";
  #   };
  #   Unit = {
  #     Before = [ "suspend.target" "sleep.target" ];
  #     ConditionEnvironment = "WAYLAND_DISPLAY";
  #     Environment = "WAYLAND_DISPLAY=wayland-1";
  #   };
  #   Install.WantedBy = [ "suspend.target" "sleep.target" ];
  # };

  security.pam.services.swaylock.text = "auth include login";

  # security.pam.services.swaylock = {}

  # - security.pam.services.swaylock.text = builtins.readFile "${pkgs.swaylock}/etc/pam.d/swaylock";
  # + security.pam.services.swaylock.text = builtins.readFile "''${pkgs.swaylock}/etc/pam.d/swaylock";
  # security.pam.services.swaylock.text = lib.fileContents "${pkgs.swaylock}/etc/pam.d/swaylock";
}
