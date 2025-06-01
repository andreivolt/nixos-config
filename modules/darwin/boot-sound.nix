{...}: {
  system.activationScripts.bootSound.text = ''
    echo 'disable boot sound'
    /usr/sbin/nvram SystemAudioVolume=%80
  '';
}