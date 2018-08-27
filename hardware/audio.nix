{ config, pkgs, ... }:

{
  hardware.pulseaudio = { enable = true; package = pkgs.pulseaudioFull; };

  environment.systemPackages = with pkgs; let
    audio = pkgs.stdenv.mkDerivation rec {
      name = "audio";

      src = [(pkgs.writeScript name ''
        #!/usr/bin/env bash

        controller='A4:34:D9:97:A7:EC'

        bt_headset_macs=$(sudo sh -c "grep -l 0000110b-0000-1000-8000-00805f9b34fb /var/lib/bluetooth/$controller/*/info" | cut -d/ -f6)

        declare -A sinks
        sinks=(
            [earbuds]=bluez_sink.C0_28_8D_25_99_38.a2dp_sink
            [headset]=bluez_sink.04_5D_4B_EA_1D_09.a2dp_sink
            [speakers]=alsa_output.pci-0000_00_1f.3.analog-stereo
        )

        current_sink=$(pactl list short sinks | awk '/RUNNING/ { print $2 }')


        bt-setup() {
            device=$(awk -F. '{ gsub(/_/, ":", $2); print $2 }' <<<$1)

            expect - <<<"
            set prompt \"#\"

            spawn bluetoothctl; expect -re \$prompt

            send \"select $controller\r\"; expect \"Controller\"
            send \"power off\r\"; expect \"succeeded\"; send \"power on\r\"; expect \"succeeded\"

            send \"connect $device\r\"; expect \"successful\"

            send \"quit\r\"
            "

            pactl set-card-profile bluez_card.''${device//:/_} a2dp_sink
        }


        sink=$(
            [[ $1 == toggle ]] &&
                {
                    [[ $current_sink == ''${sinks[headset]} ]] &&
                        echo ''${sinks[speakers]} ||
                            echo ''${sinks[headset]}
                } ||
                    echo ''${sinks[$1]}
            )

        [[ $sink == bluez* ]] && bt-setup $sink

        pactl list short sink-inputs | awk '{ print $1 }' | xargs -i -n1 pactl move-sink-input {} $sink
        pactl set-default-sink $sink

      '')];

      unpackPhase = "true";

      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/${name}
      '';
    };

    google-tts = pkgs.stdenv.mkDerivation rec {
      name = "google-tts";

      src = [(pkgs.writeScript name (let api_key = (import ../credentials.nix).google_api_key; in ''
        #!/usr/bin/env bash

        text="$*"

        ${pkgs.curl}/bin/curl "https://texttospeech.googleapis.com/v1beta1/text:synthesize?key=${api_key}" \
            -H "Content-Type: application/json" \
            --data "{
              'input':{
                'text':\"$text\"
              },
              'voice':{
                'languageCode':'en-us',
                'name':'en-US-Wavenet-C',
                'ssmlGender':'FEMALE'
              },
              'audioConfig':{
                'audioEncoding':'OGG_OPUS'
              }
            }" |
        ${pkgs.jq}/bin/jq .audioContent -r | base64 --decode |
        ${pkgs.mpv}/bin/mpv -
      ''))];

      unpackPhase = "true";

      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/${name}
      '';
    };

    volume = pkgs.stdenv.mkDerivation rec {
      name = "volume";

      src = [(pkgs.writeScript name ''
        #!/usr/bin/env bash

        set-volume() {
            ${pkgs.pamixer}/bin/pamixer --unmute

            case $1 in
                +*) ${pkgs.pamixer}/bin/pamixer --increase ''${1/+/} ;;
                -*) ${pkgs.pamixer}/bin/pamixer --decrease ''${1/-/} ;;
            esac
        }

        get-volume() {
            ${pkgs.pamixer}/bin/pamixer --get-volume
        }

        mute-toggle() {
            ${pkgs.pamixer}/bin/pamixer --toggle-mute
        }

        case $1 in
            up) set-volume +2 ;;
            down) set-volume -2 ;;
            mute-toggle) mute-toggle;;
        esac

        ${pkgs.libnotify}/bin/notify-send --app-name volume "volume" $(get-volume)
      '')];

      unpackPhase = "true";

      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/${name}
      '';
    };
  in [
    alsaPlugins
    alsaUtils
    audio
    google-tts
    volume
  ];
}
