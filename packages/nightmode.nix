self: super: with super; {

nightmode = writeScriptBin "nightmode" ''
  #!${zsh}/bin/zsh

  [ ! -f /tmp/.nightmode ] && echo 'REDSHIFT_TEMP=6500; REDSHIFT_BRIGTHNESS=1' > /tmp/.nightmode
  source /tmp/.nightmode

  temperature_increment=2
  brightness_increment=0.0005

  while getopts ":t:b:-x:" o; do
    sign=$OPTARG

    repeat 150 {
      case $o in
        t)
          (! [[ $REDSHIFT_TEMP -eq 6500 && $sign = '+' ]]) &&
            REDSHIFT_TEMP=$(($REDSHIFT_TEMP $sign $temperature_increment)) ;;
        b)
          (! [[ $REDSHIFT_BRIGTHNESS -eq 1 && $sign = '+' ]]) &&
            REDSHIFT_BRIGTHNESS=$(($REDSHIFT_BRIGTHNESS $sign $brightness_increment)) ;;
        -x)
          ${redshift}/bin/redshift -P -O 6000 -b 1; rm /tmp/.nightmode; exit ;;
      esac

      ${redshift}/bin/redshift \
        -P \
        -O $REDSHIFT_TEMP -b $REDSHIFT_BRIGTHNESS \
      &>/dev/null

      sleep 0.001
    }
  done

  ${libnotify}/bin/notify-send "
    t: $REDSHIFT_TEMP
    b: $REDSHIFT_BRIGTHNESS
  "

  echo "REDSHIFT_TEMP=$REDSHIFT_TEMP; REDSHIFT_BRIGTHNESS=$REDSHIFT_BRIGTHNESS" > /tmp/.nightmode'';

}
