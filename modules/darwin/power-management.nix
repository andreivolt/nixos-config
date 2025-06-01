{...}: {
  system.activationScripts.powerManagement.text = ''
    echo 'keep awake when remote session active when on power'
    pmset -c ttyskeepawake 1
    pmset -b ttyskeepawake 0
  '';
}