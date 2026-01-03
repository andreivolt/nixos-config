# Screensaver configuration - idle trigger and manual command
{ pkgs, ... }: {
  # Idle screensaver - plasma shader, 10min idle, internal display only
  services.glsl-screensaver = {
    enable = true;
    visual = "plasma";
    timeout = 600;
    monitor = "eDP-1";
  };

  # Manual trigger command
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "screensaver" ''
      # Save current focused monitor and window
      PREV_MON=$(${pkgs.hyprland}/bin/hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.focused) | .name')
      PREV_ADDR=$(${pkgs.hyprland}/bin/hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '.address')

      # Launch screensaver in background
      ${pkgs.callPackage ../../pkgs/screensaver {}}/bin/screensaver \
        --fps 60 --shader plasma --monitor eDP-1 "$@" &
      PID=$!

      # Kill screensaver on Ctrl+C
      trap "kill $PID 2>/dev/null" INT TERM

      # Restore focus after brief delay
      sleep 0.2
      ${pkgs.hyprland}/bin/hyprctl dispatch focusmonitor "$PREV_MON" >/dev/null
      [ -n "$PREV_ADDR" ] && [ "$PREV_ADDR" != "null" ] && \
        ${pkgs.hyprland}/bin/hyprctl dispatch focuswindow "address:$PREV_ADDR" >/dev/null

      # Wait for screensaver to exit
      wait $PID
    '')
  ];
}
