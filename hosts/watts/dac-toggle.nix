{ config, lib, pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "dac-toggle" ''
      read -r IFI_ID PROFILE < <(${pkgs.pipewire}/bin/pw-dump | ${pkgs.jq}/bin/jq -r '
        .[] | select(.info.props["device.name"] // "" | test("iFi"; "i"))
        | "\(.id) \(.info.params.Profile[0].index)"
      ')

      if [ -z "$IFI_ID" ]; then
        ${pkgs.libnotify}/bin/notify-send -u critical "DAC Toggle" "iFi DAC not found"
        exit 1
      fi

      if [ "$PROFILE" = "0" ]; then
        ${pkgs.wireplumber}/bin/wpctl set-profile "$IFI_ID" 1
        ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_SINK@ 0
        ${pkgs.libnotify}/bin/notify-send -i audio-card "iFi DAC" "PipeWire mode"
      else
        ${pkgs.wireplumber}/bin/wpctl set-profile "$IFI_ID" 0
        ${pkgs.libnotify}/bin/notify-send -i audio-card "iFi DAC" "Exclusive mode (ALSA)"
      fi
    '')
  ];
}
