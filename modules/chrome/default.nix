{
  security.chromiumSuidSandbox.enable = true;

  programs.chromium = {
    enable = true;
    extensions = import ./chrome-extensions.nix;
    extraOpts = {
      "WelcomePageOnOSUpgradeEnabled" = false;
      "DefaultBrowserSettingEnabled" = false;
      "SpellcheckEnabled" = true;
      "SpellcheckLanguage" = [
        "fr-FR"
        "en-US"
        "ro"
      ];
    };
  };
}
