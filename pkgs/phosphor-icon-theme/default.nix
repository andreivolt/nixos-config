{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  gtk3,
}:
let
  src = fetchFromGitHub {
    owner = "phosphor-icons";
    repo = "core";
    rev = "d42782b2abe747d904b971ccab48b182a1455f86"; # v2.0.8
    hash = "sha256-ayUXzJmMg8xw9IZ1QGVWcp/FpHktDZmqKGnVLORa88Y=";
  };

  colors = import ../../shared/colors.nix;
  fgColor = colors.ui.fg; # #d4d0ca

  # Icon name mappings: destination → source phosphor icon
  # Includes desktop file Icon names, Wayland app_ids, and freedesktop categories
  appMappings = {
    # Browsers
    "chromium" = "google-chrome-logo";
    "chromium-browser" = "google-chrome-logo";
    "preferences-web-browser-shortcuts" = "globe";
    # Telegram
    "telegram" = "telegram-logo";
    "telegram-desktop" = "telegram-logo";
    "org.telegram.desktop" = "telegram-logo";
    # WhatsApp / WasIstLos
    "com.github.xeco23.WasIstLos" = "whatsapp-logo";
    "wasistlos" = "whatsapp-logo";
    # Chat
    "weechat" = "chat-dots";
    "discord" = "discord-logo";
    "slack" = "slack-logo";
    # Music / Audio / Video
    "spotify" = "spotify-logo";
    "spotify-client" = "spotify-logo";
    "mpv" = "play-circle";
    "org.pulseaudio.pavucontrol" = "speaker-high";
    # Terminals
    "kitty" = "terminal-window";
    "com.mitchellh.ghostty" = "terminal-window";
    "ghostty" = "terminal-window";
    # Text editors / IDEs
    "emacs" = "code";
    "nvim" = "code";
    "neovide" = "code";
    "sublime-text" = "code";
    "sublime_text" = "code";
    "zed" = "code";
    # File managers
    "pcmanfm" = "folder-open";
    "yazi" = "folder-open";
    # Document viewers
    "org.pwmt.zathura" = "book-open";
    "zathura" = "book-open";
    # Image viewers
    "swayimg" = "image";
    "multimedia-photo-viewer" = "image";
    # System monitors
    "btop" = "chart-line-up";
    "htop" = "chart-line-up";
    # Network / VPN
    "mullvad-vpn" = "shield-check";
    "dev.deedles.Trayscale" = "share-network";
    "nm-device-wireless" = "wifi-high";
    "preferences-system-network" = "gear";
    "preferences-system-network-connection" = "plugs-connected";
    "preferences-system-network-proxy" = "globe-simple";
    # System / Utilities
    "applications-system" = "gear";
    "applications-system-symbolic" = "gear";
    "nix-snowflake" = "book-open-text";
    "preferences-desktop-theme" = "paint-brush";
    "kdeconnect" = "device-mobile";
    "de.feschber.LanMouse" = "mouse";
    "scrcpy" = "device-mobile";
    "application-exit" = "power";
    "user-trash" = "trash";
    # 3D / Graphics
    "glslViewer" = "cube";
  };

  # Systray status icons: name → { src, color }
  statusIcons = {
    "caffeine-on" = { icon = "eye"; color = fgColor; };
    "caffeine-off" = { icon = "eye-slash"; color = "#7a756d"; };
    "lan-mouse-on" = { icon = "mouse"; color = "#7a9aaa"; };
    "lan-mouse-off" = { icon = "mouse"; color = "#4d4a46"; };
    "com.github.xeco23.WasIstLos-tray" = { icon = "whatsapp-logo"; color = fgColor; };
    "com.github.xeco23.WasIstLos-tray-attention" = { icon = "whatsapp-logo"; color = "#d07070"; };
    # KDE Connect indicator
    "kdeconnectindicatordark" = { icon = "device-mobile"; color = fgColor; };
    "kdeconnect-tray-off" = { icon = "device-mobile"; color = "#4d4a46"; };
    # NetworkManager signal icons (secure variants get lock overlay)
    "nm-signal-100" = { icon = "wifi-high"; color = fgColor; };
    "nm-signal-100-secure" = { icon = "wifi-high"; color = fgColor; overlay = "lock-simple"; };
    "nm-signal-75" = { icon = "wifi-high"; color = "#b0aca4"; };
    "nm-signal-75-secure" = { icon = "wifi-high"; color = "#b0aca4"; overlay = "lock-simple"; };
    "nm-signal-50" = { icon = "wifi-medium"; color = "#7a756d"; };
    "nm-signal-50-secure" = { icon = "wifi-medium"; color = "#7a756d"; overlay = "lock-simple"; };
    "nm-signal-25" = { icon = "wifi-low"; color = "#7a756d"; };
    "nm-signal-25-secure" = { icon = "wifi-low"; color = "#7a756d"; overlay = "lock-simple"; };
    "nm-signal-0" = { icon = "wifi-none"; color = "#4d4a46"; };
    "nm-signal-0-secure" = { icon = "wifi-none"; color = "#4d4a46"; overlay = "lock-simple"; };
    "nm-no-connection" = { icon = "wifi-slash"; color = "#c45050"; };
    # NetworkManager signal + VPN icons (green tint = VPN active)
    "nm-signal-100-vpn" = { icon = "wifi-high"; color = "#8aaa8a"; };
    "nm-signal-100-secure-vpn" = { icon = "wifi-high"; color = "#8aaa8a"; overlay = "lock-simple"; };
    "nm-signal-75-vpn" = { icon = "wifi-high"; color = "#7a9a7a"; };
    "nm-signal-75-secure-vpn" = { icon = "wifi-high"; color = "#7a9a7a"; overlay = "lock-simple"; };
    "nm-signal-50-vpn" = { icon = "wifi-medium"; color = "#5a7a5a"; };
    "nm-signal-50-secure-vpn" = { icon = "wifi-medium"; color = "#5a7a5a"; overlay = "lock-simple"; };
    "nm-signal-25-vpn" = { icon = "wifi-low"; color = "#5a7a5a"; };
    "nm-signal-25-secure-vpn" = { icon = "wifi-low"; color = "#5a7a5a"; overlay = "lock-simple"; };
    "nm-signal-0-vpn" = { icon = "wifi-none"; color = "#3a5a3a"; };
    "nm-signal-0-secure-vpn" = { icon = "wifi-none"; color = "#3a5a3a"; overlay = "lock-simple"; };
    # VPN standalone icons
    "nm-vpn-connecting01" = { icon = "shield"; color = "#5a7a5a"; };
    "nm-vpn-connecting02" = { icon = "shield"; color = "#7a9a7a"; };
    "nm-vpn-connecting03" = { icon = "shield"; color = "#8aaa8a"; };
    "nm-vpn-active-lock" = { icon = "shield-check"; color = "#8aaa8a"; };
    "nm-vpn-standalone-lock" = { icon = "shield-check"; color = "#8aaa8a"; };
    # Blueman / Bluetooth tray
    "blueman-active" = { icon = "bluetooth"; color = fgColor; };
    "blueman-disabled" = { icon = "bluetooth-slash"; color = "#4d4a46"; };
    "blueman-tray" = { icon = "bluetooth"; color = fgColor; };
    "bluetooth-active" = { icon = "bluetooth"; color = fgColor; };
    "bluetooth-disabled" = { icon = "bluetooth-slash"; color = "#4d4a46"; };
    # Telegram tray
    "org.telegram.desktop-symbolic" = { icon = "telegram-logo"; color = fgColor; };
    # Battery (upower icon names for ironbar battery widget)
    "battery-full-charged-symbolic" = { icon = "battery-full"; color = "#b0aca4"; };
    "battery-full-symbolic" = { icon = "battery-full"; color = "#b0aca4"; };
    "battery-full-charging-symbolic" = { icon = "battery-charging"; color = "#b0aca4"; };
    "battery-good-symbolic" = { icon = "battery-high"; color = "#b0aca4"; };
    "battery-good-charging-symbolic" = { icon = "battery-charging"; color = "#b0aca4"; };
    "battery-low-symbolic" = { icon = "battery-medium"; color = "#b09a6d"; };
    "battery-low-charging-symbolic" = { icon = "battery-charging"; color = "#b09a6d"; };
    "battery-caution-symbolic" = { icon = "battery-low"; color = "#cc6666"; };
    "battery-caution-charging-symbolic" = { icon = "battery-charging"; color = "#cc6666"; };
    "battery-empty-symbolic" = { icon = "battery-empty"; color = "#cc6666"; };
    "battery-missing-symbolic" = { icon = "battery-warning"; color = "#cc6666"; };
    # Mullvad VPN tray
    "mullvad-connected" = { icon = "shield-check"; color = fgColor; };
    "mullvad-disconnected" = { icon = "shield"; color = "#4d4a46"; };
    "mullvad-connecting" = { icon = "shield"; color = "#7a756d"; };
  };

  # App mappings: colorized copies (not symlinks) so currentColor becomes visible
  mkAppIcons = lib.concatStringsSep "\n" (lib.mapAttrsToList (dest: srcName: ''
    sed 's/fill="currentColor"/fill="${fgColor}"/g' \
      ${src}/assets/regular/${srcName}.svg \
      > $out/share/icons/Phosphor/scalable/apps/${dest}.svg
  '') appMappings);

  mkStatusIcons = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: { icon, color, overlay ? null }:
    if overlay == null then ''
      sed 's/fill="currentColor"/fill="${color}"/g' \
        ${src}/assets/regular/${icon}.svg \
        > $out/share/icons/Phosphor/scalable/status/${name}.svg
    '' else ''
      base_path=$(sed -n 's/.*<path d="\([^"]*\)".*/\1/p' ${src}/assets/regular/${icon}.svg)
      overlay_path=$(sed -n 's/.*<path d="\([^"]*\)".*/\1/p' ${src}/assets/fill/${overlay}-fill.svg)
      cat > $out/share/icons/Phosphor/scalable/status/${name}.svg << SVGEOF
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" fill="${color}"><path d="$base_path"/><g transform="translate(156,150) scale(0.4)"><path d="$overlay_path"/></g></svg>
      SVGEOF
    '') statusIcons);

in
stdenvNoCC.mkDerivation {
  pname = "phosphor-icon-theme";
  version = "2.0.8";

  dontUnpack = true;

  nativeBuildInputs = [ gtk3 ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/icons/Phosphor/scalable/{apps,status}

    # Install all regular icons with foreground color
    for f in ${src}/assets/regular/*.svg; do
      name=$(basename "$f")
      sed 's/fill="currentColor"/fill="${fgColor}"/g' "$f" \
        > "$out/share/icons/Phosphor/scalable/apps/$name"
    done

    # App name aliases (colorized copies)
    ${mkAppIcons}

    # Colored systray status icons
    ${mkStatusIcons}

    # index.theme
    cat > $out/share/icons/Phosphor/index.theme << 'EOF'
    [Icon Theme]
    Name=Phosphor
    Comment=Phosphor Icons with Papirus-Dark fallback
    Inherits=Papirus-Dark
    Directories=scalable/apps,scalable/status

    [scalable/apps]
    Size=64
    MinSize=16
    MaxSize=512
    Type=Scalable
    Context=Applications

    [scalable/status]
    Size=64
    MinSize=16
    MaxSize=512
    Type=Scalable
    Context=Status
    EOF

    gtk-update-icon-cache $out/share/icons/Phosphor

    runHook postInstall
  '';

  meta = {
    description = "Phosphor icon theme with Papirus-Dark fallback and custom systray icons";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
