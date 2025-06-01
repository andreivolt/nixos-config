{...}: {
  system.activationScripts.menuBar.text = ''
    echo 'reduce menu bar whitespace'
    sudo -u andrei defaults write -g NSStatusItemSelectionPadding -int 16
    sudo -u andrei defaults write -g NSStatusItemSpacing -int 16
  '';
}