{...}: {
  # Google API keys for Chromium sign-in/sync
  environment.sessionVariables = {
    GOOGLE_DEFAULT_CLIENT_ID = "77185425430.apps.googleusercontent.com";
    GOOGLE_DEFAULT_CLIENT_SECRET = "OTJgUOQcT7lO7GsGZq2G4IlT";
  };

  home-manager.users.andrei = {
    programs.chromium.enable = true;
  };
}
