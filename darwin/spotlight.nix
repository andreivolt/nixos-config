{
  config,
  pkgs,
  ...
}: {
  system.defaults.CustomUserPreferences."com.apple.Spotlight"."orderedItems" = [
    { enabled = 1; name = "APPLICATIONS"; }
    { enabled = 1; name = "MENU_EXPRESSION"; }
    { enabled = 0; name = "CONTACT"; }
    { enabled = 1; name = "MENU_CONVERSION"; }
    { enabled = 0; name = "MENU_DEFINITION"; }
    { enabled = 0; name = "SOURCE"; }
    { enabled = 1; name = "DOCUMENTS"; }
    { enabled = 0; name = "EVENT_TODO"; }
    { enabled = 0; name = "DIRECTORIES"; }
    { enabled = 0; name = "FONTS"; }
    { enabled = 0; name = "IMAGES"; }
    { enabled = 0; name = "MESSAGES"; }
    { enabled = 0; name = "MOVIES"; }
    { enabled = 0; name = "MUSIC"; }
    { enabled = 0; name = "MENU_OTHER"; }
    { enabled = 0; name = "PDF"; }
    { enabled = 0; name = "PRESENTATIONS"; }
    { enabled = 0; name = "MENU_SPOTLIGHT_SUGGESTIONS"; }
    { enabled = 0; name = "SPREADSHEETS"; }
    { enabled = 1; name = "SYSTEM_PREFS"; }
    { enabled = 0; name = "TIPS"; }
    { enabled = 0; name = "BOOKMARKS"; }
  ];
}
