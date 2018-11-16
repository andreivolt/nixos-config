self: super: with super; {

google-tts = writeShellScriptBin "google-tts" ''
  text="$*"

  ${curl}/bin/curl "https://texttospeech.googleapis.com/v1beta1/text:synthesize?key=${(import /home/avo/lib/credentials.nix).google_api_key}" \
    -H "Content-Type: application/json" \
    --data "{ 'input': { 'text':\"$text\" },
              'voice': { 'languageCode':'en-us', 'name':'en-US-Wavenet-C', 'ssmlGender':'FEMALE' },
              'audioConfig': { 'audioEncoding':'OGG_OPUS' } }" |
  ${jq}/bin/jq .audioContent -r | base64 --decode |
  ${mpv}/bin/mpv -'';

}
