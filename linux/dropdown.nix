{ pkgs, ... }:

let
  dropdownGuard = pkgs.writeShellApplication {
    name = "hyprland-dropdown-guard";
    runtimeInputs = with pkgs; [ hyprland jq socat ];
    text = ''
      # Evict non-dropdown windows from special:dropdown to the last active workspace
      while read -r line; do
        case "$line" in
          openwindow*) ;;
          *) continue ;;
        esac

        addr="''${line#*>>}"
        addr="''${addr%%,*}"
        sleep 0.1

        read -r class ws < <(hyprctl clients -j | jq -r ".[] | select(.address == \"0x$addr\") | [.class, .workspace.name] | @tsv")
        [[ "$ws" != "special:dropdown" ]] && continue
        [[ "$class" == "dropdown" ]] && continue

        # Find the focused monitor's active workspace
        target=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .activeWorkspace.id')
        target="''${target:-1}"

        hyprctl dispatch movetoworkspace "$target,address:0x$addr"
      done < <(socat -t 999999 - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock")
    '';
  };
in
{
  home-manager.users.andrei = {
    systemd.user.services.dropdown = {
      Unit = {
        Description = "Dropdown terminal";
        PartOf = [ "hyprland-session.target" ];
        After = [ "hyprland-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.kitty}/bin/kitty --class dropdown";
        Restart = "always";
        RestartSec = 1;
      };
      Install.WantedBy = [ "hyprland-session.target" ];
    };
    systemd.user.services.hyprland-dropdown-guard = {
      Unit = {
        Description = "Evict non-dropdown windows from special:dropdown";
        PartOf = [ "hyprland-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${dropdownGuard}/bin/hyprland-dropdown-guard";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install.WantedBy = [ "hyprland-session.target" ];
    };
  };
}