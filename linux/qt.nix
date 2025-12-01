{pkgs, ...}: {
  home-manager.users.andrei = {
    home.packages = with pkgs; [
      libsForQt5.qtstyleplugin-kvantum
      # libsForQt5.breeze-qt5  # Removed from nixpkgs-unstable
    ];

    # Configure qt5ct for dark theme
    xdg.configFile."qt5ct/qt5ct.conf".text = ''
      [Appearance]
      color_scheme_path=/run/current-system/sw/share/qt5ct/colors/darker.conf
      custom_palette=false
      icon_theme=Tela-dark
      standard_dialogs=default
      style=Breeze

      [Fonts]
      fixed="Noto Sans,10,-1,5,50,0,0,0,0,0"
      general="Noto Sans,10,-1,5,50,0,0,0,0,0"

      [Interface]
      activate_item_on_single_click=1
      buttonbox_layout=0
      cursor_flash_time=1000
      dialog_buttons_have_icons=1
      double_click_interval=400
      gui_effects=@Invalid()
      keyboard_scheme=2
      menus_have_icons=true
      show_shortcuts_in_context_menus=true
      stylesheets=@Invalid()
      toolbutton_style=4
      underline_shortcut=1
      wheel_scroll_lines=3

      [SettingsWindow]
      geometry=@ByteArray()
    '';

    # Configure qt6ct for dark theme
    xdg.configFile."qt6ct/qt6ct.conf".text = ''
      [Appearance]
      color_scheme_path=
      custom_palette=false
      icon_theme=Tela-dark
      standard_dialogs=default
      style=Breeze

      [Fonts]
      fixed="Noto Sans,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
      general="Noto Sans,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

      [Interface]
      activate_item_on_single_click=1
      buttonbox_layout=0
      cursor_flash_time=1000
      dialog_buttons_have_icons=1
      double_click_interval=400
      gui_effects=@Invalid()
      keyboard_scheme=2
      menus_have_icons=true
      show_shortcuts_in_context_menus=true
      stylesheets=@Invalid()
      toolbutton_style=4
      underline_shortcut=1
      wheel_scroll_lines=3
    '';
  };

  qt = {
    enable = true;
    platformTheme = "qt5ct";
    style = null;  # Don't set QT_STYLE_OVERRIDE, let qt5ct/qt6ct handle it
  };
}
