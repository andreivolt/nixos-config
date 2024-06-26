{
  home-manager.users.andrei.home.file.".weechat/matrix.conf" = ''
    [network]
    autoreconnect_delay_growing = 2
    autoreconnect_delay_max = 600
    debug_buffer = off
    debug_category = all
    debug_level = error
    fetch_backlog_on_pgup = on
    lag_min_show = 500
    lag_reconnect = 90
    lazy_load_room_users = off
    max_backlog_sync_events = 10
    max_initial_sync_events = 30
    max_nicklist_users = 5000
    print_unconfirmed_messages = on
    read_markers_conditions = "''${markers_enabled}"
    resending_ignores_devices = on
    typing_notice_conditions = "''${typing_enabled}"

    [look]
    bar_item_typing_notice_prefix = "Typing: "
    busy_sign = "⏳"
    code_block_margin = 2
    code_blocks = on
    disconnect_sign = "❌"
    encrypted_room_sign = "🔐"
    encryption_warning_sign = "⚠️ "
    human_buffer_names = off
    markdown_input = on
    max_typing_notice_item_length = 50
    new_channel_position = none
    pygments_style = "native"
    quote_wrap = 67
    redactions = strikethrough
    server_buffer = merge_with_core

    [color]
    error_message_bg = default
    error_message_fg = darkgray
    nick_prefixes = "admin=lightgreen;mod=lightgreen;power=yellow"
    quote_bg = default
    quote_fg = lightgreen
    unconfirmed_message_bg = default
    unconfirmed_message_fg = darkgray
    untagged_code_bg = default
    untagged_code_fg = blue

    [server]
    matrix_org.autoconnect = on
    matrix_org.address = "matrix.org"
    matrix_org.port = 443
    matrix_org.proxy = ""
    matrix_org.ssl_verify = on
    matrix_org.username = "${builtins.getEnv "MATRIX_USERNAME"}"
    matrix_org.password = "${builtins.getEnv "MATRIX_PASSWORD"}"
    matrix_org.device_name = "Weechat Matrix"
    matrix_org.autoreconnect_delay = 10
    matrix_org.sso_helper_listening_port = 0
  ''
    }
