{...}: {
  # ads
  system.defaults.CustomUserPreferences."com.apple.AdLib" = {
    allowApplePersonalizedAdvertising = false;
    allowIdentifierForAdvertising = false;
  };

  # disable Siri data sharing
  system.defaults.CustomUserPreferences."com.apple.assistant.support"."Search Queries Data Sharing Status" = 2;
}
