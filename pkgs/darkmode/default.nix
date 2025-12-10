{
  writeShellScriptBin,
  stdenv,
}:
writeShellScriptBin "darkmode" (
  if stdenv.hostPlatform.isDarwin
  then ''
    osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to not dark mode'
  ''
  else ''
    current=$(gsettings get org.gnome.desktop.interface color-scheme)
    if [[ "$current" == "'prefer-dark'" ]]; then
      gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
      gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
      gsettings set org.gnome.desktop.interface.a11y high-contrast false 2>/dev/null
      dconf write /org/gnome/desktop/interface/gtk-application-prefer-dark-theme false 2>/dev/null
      plasma-apply-colorscheme BreezeLight 2>/dev/null
    else
      gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
      gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
      dconf write /org/gnome/desktop/interface/gtk-application-prefer-dark-theme true 2>/dev/null
      plasma-apply-colorscheme BreezeDark 2>/dev/null
    fi
  ''
)
