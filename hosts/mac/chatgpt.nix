{
  homebrew.casks = ["chatgpt"];

  system.defaults.CustomUserPreferences."com.openai.chat" = {
    "openUniversalLinksInBrowser" = 1;
    "desktopMenuBarBehavior" = "{\"always\":{}}";
  };
}
