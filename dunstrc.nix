{ theme }:

{
  global = {
    "alignment" = "left";
    "bounce_freq" = "0";
    "browser" = "qutebrowser";
    "dmenu" = "rofi -dmenu";
    "follow" = "keyboard";
    "font" = "Roboto Condensed 16";
    "format" = "<b>%s</b>: %b";
    "frame_color" = "#000000";
    "frame_width" = "1";
    "geometry" = "600x15+150-350";
    "horizontal_padding" = "16";
    "idle_threshold" = "120";
    "ignore_newline" = "yes";
    "indicate_hidden" = "yes";
    "line_height" = "0";
    "markup" = "yes";
    "monitor" = "0";
    "padding" = "12";
    "separator_color" = "auto";
    "separator_height" = "1";
    "show_age_threshold" = "60";
    "sort" = "yes";
    "startup_notification" = "false";
    "sticky_history" = "yes";
    "transparency" = "5";
    "word_wrap" = "yes";
  };

  shortcuts = {
    "close_all" = "ctrl+shift+space";
    "history" = "ctrl+space";
    "context" = "ctrl+e";
  };

  urgency_low = {
    "background" = "#000000";
    "foreground" = "#aaaaaa";
    "timeout" = 3;
  };

  urgency_normal = {
    "background" = "#000000";
    "foreground" = "#ffffff";
    "timeout" = 3;
  };

  urgency_critical = {
    "background" = "#bb0000";
    "foreground" = "#ffffff";
    "timeout" = 3;
  };

  irc = {
    "appname" = "irc";
    "summary" = "*ndrei*";
    "format" = "%b";
    "script" = "tts";
  };

  volume = {
    "appname" = "volume";
    "urgency" = "low";
    "stack_duplicates" = false;
    "format" = "%b";
    "hide_duplicates_count" = true;
    "history_length" = "1";
    "timeout" = "1";
  };

  ignore-dropbox = {
    "appname" = "Dropbox";
    "summary" = "*";
    "format" = "";
  };

  sticky = {
    "appname" = "sticky";
    "format" = "%s %b";
    "background" = "#b58900";
    "foreground" = "#002b36";
    "timeout" = 0;
  };

  clock = {
    "appname" = "clock";
    "format" = "%s %b";
    "background" = "#859900";
    "foreground" = "#002b36";
    "timeout" = "30";
  };

  todo = {
    "appname" = "todo";
    "format" = "TODO %b";
    "foreground" = "#002b36";
    "background" = "#859900";
    "timeout" = 0;
  };
}
