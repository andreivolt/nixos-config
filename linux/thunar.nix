{
  pkgs,
  lib,
  ...
}: {
  # Thunar and thumbnail support
  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-archive-plugin
      thunar-volman
    ];
  };

  # Tumbler thumbnail service
  services.tumbler.enable = true;

  environment.systemPackages = with pkgs; [
    xfce.xfconf
    # Thumbnailers
    ffmpegthumbnailer
    gnome-epub-thumbnailer
    libheif
    webp-pixbuf-loader
  ] ++ lib.optionals (pkgs.stdenv.hostPlatform.isx86_64) [
    # RAW image thumbnails (x86 only)
    libraw
  ];

  # Set Thunar as default file manager
  xdg.mime.defaultApplications = {
    "inode/directory" = "thunar.desktop";
  };

  home-manager.users.andrei = {
    # Thunar configuration via xfconf XML (avoids xfconfd dependency)
    xdg.configFile."xfce4/xfconf/xfce-perchannel-xml/thunar.xml" = {
      force = true;
      text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="thunar" version="1.0">
        <property name="last-details-view-zoom-level" type="string" value="THUNAR_ZOOM_LEVEL_38_PERCENT"/>
        <property name="last-icon-view-zoom-level" type="string" value="THUNAR_ZOOM_LEVEL_100_PERCENT"/>
        <property name="last-location-bar" type="string" value="ThunarLocationEntry"/>
        <property name="last-side-pane" type="string" value="ThunarShortcutsPane"/>
        <property name="last-view" type="string" value="ThunarCompactView"/>
        <property name="misc-confirm-move-to-trash" type="bool" value="false"/>
        <property name="misc-date-style" type="string" value="THUNAR_DATE_STYLE_SHORT"/>
        <property name="misc-directories-first" type="bool" value="true"/>
        <property name="misc-recursive-permissions" type="string" value="THUNAR_RECURSIVE_PERMISSIONS_ASK"/>
        <property name="misc-show-delete-permanently" type="bool" value="true"/>
        <property name="misc-single-click" type="bool" value="false"/>
        <property name="misc-text-beside-icons" type="bool" value="false"/>
        <property name="misc-thumbnail-mode" type="string" value="THUNAR_THUMBNAIL_MODE_ALWAYS"/>
        <property name="misc-volume-management" type="bool" value="true"/>
        <property name="shortcuts-icon-size" type="string" value="THUNAR_ICON_SIZE_16"/>
        <property name="tree-icon-size" type="string" value="THUNAR_ICON_SIZE_16"/>
        <property name="last-menubar-visible" type="bool" value="false"/>
      </channel>
    '';
    };

    # GTK bookmarks (equivalent to KDE places)
    # Home and Trash are built-in, just add custom ones
    xdg.configFile."gtk-3.0/bookmarks".text = ''
      file:///home/andrei/drive drive
      file:///home/andrei/Downloads Downloads
    '';
  };
}
