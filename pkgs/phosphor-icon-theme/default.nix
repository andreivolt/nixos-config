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
    "org.kde.dolphin" = "folder-open";
    "dolphin" = "folder-open";
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
    "caffeine-on" = { icon = "eye"; color = "#e8e4df"; };
    "caffeine-off" = { icon = "eye-slash"; color = "#7a756d"; };
    "lan-mouse-on" = { icon = "mouse"; color = "#7a9aaa"; };
    "lan-mouse-off" = { icon = "mouse"; color = "#4d4a46"; };
    "com.github.xeco23.WasIstLos-tray" = { icon = "whatsapp-logo"; color = "#e8e4df"; };
    "com.github.xeco23.WasIstLos-tray-attention" = { icon = "whatsapp-logo"; color = "#d07070"; };
    # KDE Connect indicator
    "kdeconnectindicatordark" = { icon = "device-mobile"; color = "#e8e4df"; };
    "kdeconnect-tray-off" = { icon = "device-mobile"; color = "#4d4a46"; };
    # NetworkManager signal icons
    "nm-signal-100" = { icon = "wifi-high"; color = "#e8e4df"; };
    "nm-signal-100-secure" = { icon = "wifi-high"; color = "#e8e4df"; };
    "nm-signal-75" = { icon = "wifi-high"; color = "#b0aca4"; };
    "nm-signal-75-secure" = { icon = "wifi-high"; color = "#b0aca4"; };
    "nm-signal-50" = { icon = "wifi-medium"; color = "#7a756d"; };
    "nm-signal-50-secure" = { icon = "wifi-medium"; color = "#7a756d"; };
    "nm-signal-25" = { icon = "wifi-low"; color = "#7a756d"; };
    "nm-signal-25-secure" = { icon = "wifi-low"; color = "#7a756d"; };
    "nm-signal-0" = { icon = "wifi-none"; color = "#4d4a46"; };
    "nm-signal-0-secure" = { icon = "wifi-none"; color = "#4d4a46"; };
    "nm-no-connection" = { icon = "wifi-slash"; color = "#c45050"; };
    # Telegram tray
    "org.telegram.desktop-symbolic" = { icon = "telegram-logo"; color = "#e8e4df"; };
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
  };

  # App mappings: colorized copies (not symlinks) so currentColor becomes visible
  mkAppIcons = lib.concatStringsSep "\n" (lib.mapAttrsToList (dest: srcName: ''
    sed 's/fill="currentColor"/fill="${fgColor}"/g' \
      ${src}/assets/light/${srcName}-light.svg \
      > $out/share/icons/Phosphor/scalable/apps/${dest}.svg
  '') appMappings);

  mkStatusIcons = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: { icon, color }: ''
    sed 's/fill="currentColor"/fill="${color}"/g' \
      ${src}/assets/light/${icon}-light.svg \
      > $out/share/icons/Phosphor/scalable/status/${name}.svg
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

    # Install all light icons with foreground color (strip -light suffix)
    for f in ${src}/assets/light/*-light.svg; do
      name=$(basename "$f" | sed 's/-light\.svg$/.svg/')
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
    Comment=Phosphor Icons (light) with Papirus-Dark fallback
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
