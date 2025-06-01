{
  homebrew.casks = ["chatgpt"];

  system.defaults.CustomUserPreferences."com.openai.chat" = {
    "desktopAppIconBehavior" = "{\"showOnlyInMenuBar\":{}}";
    "openUniversalLinksInBrowser" = 1;
  };
}
