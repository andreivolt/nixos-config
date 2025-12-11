{ config, lib, pkgs, ... }:

let
  dacToggle = pkgs.writeShellScript "dac-toggle" ''
    # Find iFi DAC device ID dynamically
    IFI_ID=$(${pkgs.wireplumber}/bin/wpctl status | grep -i "iFi.*HD USB Audio" | grep -oP '^\s*\K\d+' | head -1)

    if [ -z "$IFI_ID" ]; then
      ${pkgs.libnotify}/bin/notify-send -u critical "Roon Toggle" "iFi DAC not found"
      exit 1
    fi

    # Check current profile (0 = off, 1+ = active)
    CURRENT=$(${pkgs.pipewire}/bin/pw-cli enum-params "$IFI_ID" Profile 2>/dev/null | grep -A1 "Profile:index" | tail -1 | grep -oP 'Int \K\d+')

    if [ "$CURRENT" = "0" ]; then
      # Currently off (Roon mode) -> switch to PipeWire
      ${pkgs.wireplumber}/bin/wpctl set-profile "$IFI_ID" 1
      ${pkgs.libnotify}/bin/notify-send -i audio-card "iFi DAC" "PipeWire mode"
    else
      # Currently active -> release for exclusive ALSA access
      ${pkgs.wireplumber}/bin/wpctl set-profile "$IFI_ID" 0
      ${pkgs.libnotify}/bin/notify-send -i audio-card "iFi DAC" "Exclusive mode (ALSA)"
    fi
  '';
in {
  # Add script to system packages
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "dac-toggle" (builtins.readFile dacToggle))
  ];
}
