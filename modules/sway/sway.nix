{ lib, pkgs, ... }:

let
  font = {
   family = "Ubuntu";
   size = 36;
  };
  theme = import ../theme.nix;

in {
  imports = [
    ./service.nix
  ];

  environment.pathsToLink = [ "/libexec" ];

  # fix "failed to take device"
  hardware.opengl.driSupport = true;

  programs.sway.enable = true;
  programs.sway.extraPackages = with pkgs; [
    gammastep
    gebaar-libinput
    grim
    mako
    wev
    slurp
    swayidle
    swaylock
    wmfocus # window picker
    wob
    wl-clipboard
    kanshi  # display configuration
    wdisplays  # display configuration
    swaybg
    oguri # animated background
    waybar
    xwayland
  ];

  # notifications
  home-manager.users.avo.programs.mako = {
    enable = true;
    width = 500;
    backgroundColor = "#00000050";
    font = "${font.family} ${toString font.size}";
    layer = "overlay";
    borderSize = 0;
    margin = "20";
    padding = "20";
  };

  programs.sway.extraSessionCommands = ''
    export XKB_DEFAULT_LAYOUT=fr
  '';

  programs.qt5ct.enable = true;

  # home-manager.users.avo = { pkgs, ... }: {
  #   home.file.".zprofile".text = ''
  #     if [[ $XDG_VTNR -eq 1 ]]; then
  #       exec dbus-launch --sh-syntax --exit-with-session sway
  #     fi
  #   '';
  # };

  environment.etc."sway/config".text = let
    display = { width = 2560; height = 1600; };
    # scratchpad_height = builtins.floor (display_height / 1.5);
    scratchpad = rec {
      width = display.width * 0.83;
      height = width / 1.5;
      pos_y = 0;
      pos_x = (display.width - width) / 2;
      opacity = 0.75;
    };
    floating_window_criteria = [
      "[app_id=imv]"
      "[app_id=mpv]"
      ''[title="Picture in picture"]''
    ];
    x = x: builtins.elemAt (builtins.match "(.*).{7}" (toString x)) 0;
    # set $scratchpad.width ${x scratchpad.width}
    # set $scratchpad.height ${x scratchpad.height}
    # set $scratchpad.pos_x ${toString scratchpad.pos_x}
    # set $scratchpad.pos_y ${x scratchpad.pos_y}
    # set $scratchpad.opacity ${x scratchpad.opacity}
  in ''
    set $scratchpad.width 2560
    set $scratchpad.height 1440
    set $scratchpad.pos_x 0
    set $scratchpad.pos_y 0
    set $scratchpad.opacity 0.75

    # set $WOBSOCK $XDG_RUNTIME_DIR/wob.sock
    # exec mkfifo $WOBSOCK && tail -f $WOBSOCK | wob
    # exec mkfifo /tmp/wob.sock && tail -f /tmp/wob.sock | wob
    # set $WOBSOCK $XDG_RUNTIME_DIR/wob.sock
    set $WOBSOCK /tmp/wob.sock
    exec mkfifo /tmp/wob.sock
    exec tail -f /tmp/wob.sock | wob


    include @sysconfdir@/sway/config.d/*

    set $lock swaylock -f -c -000001
    exec swayidle -w \
        timeout 1200 '$lock' \
        timeout 180 'swaymsg "output * dpms off"' resume 'swaymsg "output * dpms on"' \
        timeout 7200 'systemctl suspend' \
        before-sleep '$lock'
    exec mako

    # store clipboard history
    exec wl-paste -t text --watch clipman store
    # restore last history item at startup
    exec clipman restore

    # set $height $(swaymsg -t get_tree | jq .rect.height)
    # set $width $(swaymsg -t get_tree | jq .rect.width)

    default_border none
    smart_borders on
    # hide_edge_borders both

    bar mode invisible
    titlebar_padding 20 8

    output * scale 1

    output * background #000000 solid_color

    # for_window [app_id="mpv"] inhibit_idle visible
    ${lib.concatStringsSep "\n" (map (_: "for_window ${_} floating enable") floating_window_criteria)}

    set $mod Mod4

    set $left h
    set $down j
    set $up k
    set $right l

    set $term wayst

    set $menu find ~/.nix-profile/share -name '*.desktop' | xargs basename -s .desktop | menu

    bindsym $mod+Return exec $term
    bindsym $mod+Shift+c kill
    bindsym Print exec grim -g "$(slurp)" - | wl-copy -t image/png
    bindsym $mod+p exec $menu
    bindsym $mod+q reload
    bindsym $mod+i exec colortemp up
    bindsym $mod+o exec colortemp down
    bindsym $mod+Tab focus right
    bindsym $mod+Shift+Tab focus left
    bindsym $mod+$left focus left
    bindsym $mod+$down focus down
    bindsym $mod+$up focus up
    bindsym $mod+$right focus right
    bindsym $mod+t layout tabbed
    bindsym $mod+s layout toggle split
    bindsym $mod+Shift+$left move left
    bindsym $mod+Shift+$down move down
    bindsym $mod+Shift+$up move up
    bindsym $mod+Shift+$right move right
    bindsym $mod+Shift+Left move left
    bindsym $mod+Shift+Down move down
    bindsym $mod+Shift+Up move up
    bindsym $mod+Shift+Right move right

    set $resize_increment 40px
    bindsym $mod+Alt+$left resize shrink width $resize_increment
    bindsym $mod+Alt+$down resize grow height $resize_increment
    bindsym $mod+Alt+$up resize shrink height $resize_increment
    bindsym $mod+Alt+$right resize grow width $resize_increment

    bindsym $mod+b splith
    bindsym $mod+v splitv

    bindsym $mod+f fullscreen

    bindsym $mod+a focus parent

    floating_modifier $mod normal

    for_window [app_id=scratchpad] floating enable
    for_window [app_id=scratchpad] move scratchpad
    for_window [app_id=scratchpad] scratchpad show
    for_window [app_id=scratchpad] resize set $scratchpad.width $scratchpad.height
    for_window [app_id=scratchpad] move position $scratchpad.pos_x $scratchpad.pos_y

    set $scratchpad_command alacritty --app-id scratchpad -o 'background_opacity=$scratchpad.opacity'

    for_window [app_id="pavucontrol"] floating enable

    input * xkb_options ctrl:nocaps

    bindsym F1 exec pamixer --toggle-mute && ( pamixer --get-mute && echo 0 > $WOBSOCK ) || pamixer --get-volume > $WOBSOCK
    bindsym F2 exec pamixer --decrease 3 && pamixer --get-volume > $WOBSOCK
    bindsym F3 exec pamixer --increase 3 && pamixer --get-volume > $WOBSOCK
    bindsym F4 exec pactl set-source-mute @DEFAULT_SOURCE@ toggle

    bindsym Home exec playerctl previous
    bindsym End exec playerctl next

    set $black #000000
    set $white #ffffff
    set $gray #333333
    set $darkgray #222222
    set $lightgray #777777
    set $blue #285577

    set $border $black
    set $background $black
    set $text $lightgray
    set $indicator $black
    set $child_border $black
    client.unfocused $border $background $text $indicator $child_border

    set $border $blue
    set $background $blue
    set $text $white
    set $indicator $black
    set $child_border $blue
    client.focused ${theme.dark.active.background} ${theme.dark.active.background} ${theme.dark.active.foreground} $indicator $child_border

    set $border $black
    set $background $black
    set $text $gray
    set $indicator $black
    set $child_border $black
    client.focused_inactive $border $background $text $indicator $child_border

    # set $border $black
    # set $background $black
    # set $text $gray
    # set $indicator $black
    # set $child_border $black
    # client.urgent $border $background $text $indicator $child_border


    input "1133:45081:MX_Master_2S_Mouse" {
      accel_profile flat
      pointer_accel 1
    }

    input "2:7:SynPS/2_Synaptics_TouchPad" {
      dwt enabled
      tap enabled
      natural_scroll enabled
      middle_emulation enabled
    }

    font pango:${font.family} 22

    bindsym F5 mode "default"

    bindsym $mod+ampersand workspace 1
    bindsym $mod+eacute workspace 2
    bindsym $mod+quotedbl workspace 3
    bindsym $mod+apostrophe workspace 4
    bindsym $mod+parenleft workspace 5
    bindsym $mod+egrave workspace 6
    bindsym $mod+minus workspace 7
    bindsym $mod+underscore workspace 8
    bindsym $mod+ccedilla workspace 9
    bindsym $mod+agrave workspace 10

    bindsym $mod+Shift+ampersand move container to workspace 1
    bindsym $mod+Shift+eacute move container to workspace 2
    bindsym $mod+Shift+quotedbl move container to workspace 3
    bindsym $mod+Shift+apostrophe move container to workspace 4
    bindsym $mod+Shift+parenleft move container to workspace 5
    bindsym $mod+Shift+egrave move container to workspace 6
    bindsym $mod+Shift+minus move container to workspace 7
    bindsym $mod+Shift+underscore move container to workspace 8
    bindsym $mod+Shift+ccedilla move container to workspace 9
    bindsym $mod+Shift+agrave move container to workspace 10

    bindsym twosuperior scratchpad show
    bindsym $mod+x move container to scratchpad

    # Toggle the current focus between tiling and floating mode
    bindsym $mod+Shift+space floating toggle

    # Swap focus between the tiling area and the floating area
    bindsym $mod+space focus mode_toggle
  '';

  systemd.user.targets.sway-session = {
    description = "Sway compositor session";
    documentation = [ "man:systemd.special(7)" ];
    bindsTo = [ "graphical-session.target" ];
    wants = [ "graphical-session-pre.target" ];
    after = [ "graphical-session-pre.target" ];
  };

  systemd.user.services.sway2 = {
    description = "Sway - Wayland window manager";
    documentation = [ "man:sway(5)" ];
    bindsTo = [ "graphical-session.target" ];
    wants = [ "graphical-session-pre.target" ];
    after = [ "graphical-session-pre.target" ];
    # We explicitly unset PATH here, as we want it to be set by
    # systemctl --user import-environment in startsway
    environment.PATH = lib.mkForce null;
    environment.XKB_DEFAULT_LAYOUT = "fr";

    serviceConfig = {
      Type = "simple";
      ExecStart = ''
        ${pkgs.dbus}/bin/dbus-run-session ${pkgs.sway}/bin/sway --debug
      '';
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  environment.systemPackages = with pkgs; [
    polkit_gnome
    (pkgs.writeTextFile {
      name = "startsway";
      destination = "/bin/startsway";
      executable = true;
      text = ''
        #! ${pkgs.bash}/bin/bash

        # first import environment variables from the login manager
        systemctl --user import-environment
        # then start the service
        exec systemctl --user start sway2.service
      '';
    })
  ];
}
