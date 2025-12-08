{
  writeShellScriptBin,
  upower,
  coreutils,
  gawk,
  gnugrep,
}:
writeShellScriptBin "battery-time" ''
  export PATH="${upower}/bin:${coreutils}/bin:${gawk}/bin:${gnugrep}/bin:$PATH"

  bat=$(upower -e | grep battery | head -1)
  [ -z "$bat" ] && { echo "No battery found"; exit 1; }

  # Get current state from upower
  current_state=$(upower -i "$bat" | awk '/^\s+state:/{print $2}')

  # Use rate history (updates every 30s) instead of charge history (only on % change)
  hist=$(ls /var/lib/upower/history-rate-*.dat 2>/dev/null | grep -v generic | head -1)
  if [ -z "$hist" ]; then
    echo "$current_state (no history)"
    exit 0
  fi

  # Find the first entry with current state (searching backwards from end)
  transition_ts=$(tac "$hist" | awk -v state="$current_state" '
    $3 != state { print prev_ts; exit }
    { prev_ts = $1 }
  ')
  [ -z "$transition_ts" ] && transition_ts=$(head -1 "$hist" | awk '{print $1}')

  now_ts=$(date +%s)
  elapsed=$((now_ts - transition_ts))

  hours=$((elapsed / 3600))
  mins=$(((elapsed % 3600) / 60))

  if [ $hours -gt 0 ]; then
    printf "%s for %dh %dm\n" "$current_state" "$hours" "$mins"
  else
    printf "%s for %dm\n" "$current_state" "$mins"
  fi
''
