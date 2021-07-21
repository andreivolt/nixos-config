{ pkgs, ... }:


{
  home-manager.users.avo.home.packages = with pkgs; [ spotify ];

  home-manager.users.avo.programs.zsh.initExtra =
    let _ = pkgs.writeScriptBin "spotify-notifications-autokill" ''
      #!${pkgs.zsh}/bin/zsh

      while id=$(
        makoctl list \
        | jq '.data | first | select(.[]."app-name".data == "Spotify") | first | .id.data'
      ); do
        [ -z $id ] \
          && sleep 1 \
          || { sleep 10 && makoctl dismiss -n $id };
      done
    ''; in ''
      pgrep -f spotify-notifications-autokill >/dev/null ||
        setsid &>/dev/null ${_}/bin/spotify-notifications-autokill
    '';
}
