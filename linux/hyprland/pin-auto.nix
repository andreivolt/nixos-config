# Auto-pin floating windows matching specific patterns (e.g., Picture-in-Picture)
{pkgs, ...}: let
  script = pkgs.writeShellApplication {
    name = "hyprland-auto-pin";
    runtimeInputs = with pkgs; [hyprland jq socat findutils];
    text = ''
      # Usage: hyprland-auto-pin [class|title:pattern]
      # Example: hyprland-auto-pin mpv
      # Example: hyprland-auto-pin "title:Picture in picture"
      #
      # Note: Pinned windows cannot go fullscreen in Hyprland.
      # mpv-smart-fullscreen.lua handles unpin on entry; this script re-pins on exit.

      pattern="$1"
      lockdir="/tmp/hypr-auto-pin-locks"
      mkdir -p "$lockdir"

      while read -r line; do
          case "$line" in
              openwindow*)
                  addr="''${line#*>>}"
                  addr="''${addr%%,*}"
                  sleep 0.2  # Let window settle
                  ;;
              changefloatingmode*)
                  addr="''${line#*>>}"
                  addr="''${addr%%,*}"
                  ;;
              fullscreen*) # fullscreen>>STATE — re-pin after fullscreen exit
                  addr=$(hyprctl activewindow -j | jq -r '.address // empty' | sed 's/^0x//')
                  [[ -z "$addr" ]] && continue
                  sleep 0.2  # Let window settle after fullscreen exit
                  ;;
              *) continue ;;
          esac

          # Per-address lock to prevent double-processing
          lockfile="$lockdir/$addr"
          if [[ -f "$lockfile" ]] && [[ $(find "$lockfile" -mmin -0.05 2>/dev/null) ]]; then
              continue
          fi

          # Get window info
          read -r floating pinned class title < <(hyprctl clients -j | jq -r ".[] | select(.address == \"0x$addr\") | [.floating, .pinned, .class, .title] | @tsv")

          [[ "$floating" != "true" ]] && continue
          [[ "$pinned" == "true" ]] && continue

          # Check pattern match (substring/glob matching)
          if [[ "$pattern" == title:* ]]; then
              match_pattern="''${pattern#title:}"
              [[ "$title" != *"$match_pattern"* ]] && continue
          else
              [[ "$class" != "$pattern" ]] && continue
          fi

          # Pin the window
          touch "$lockfile"
          hyprctl dispatch pin address:0x"$addr"
          sleep 0.3
          rm -f "$lockfile"
      done < <(socat -t 999999 - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock")
    '';
  };
in {
  # mpv: handle fullscreen on pinned windows via hyprctl instead of WM request
  xdg.configFile."mpv/scripts/smart-fullscreen.lua".source = ./mpv-smart-fullscreen.lua;

  systemd.user.services = {
    hyprland-auto-pin-pip = {
      Unit = {
        Description = "Auto-pin Picture-in-Picture windows";
        PartOf = ["graphical-session.target"];
      };
      Service = {
        Type = "simple";
        ExecStart = "${script}/bin/hyprland-auto-pin \"title:Picture in picture\"";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install.WantedBy = ["graphical-session.target"];
    };
    hyprland-auto-pin-mpv = {
      Unit = {
        Description = "Auto-pin mpv windows";
        PartOf = ["graphical-session.target"];
      };
      Service = {
        Type = "simple";
        ExecStart = "${script}/bin/hyprland-auto-pin mpv";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
