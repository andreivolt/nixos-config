{
  security.chromiumSuidSandbox.enable = true;

  programs.chromium = {
      # homepageLocation = "https://www.google.com";
      # defaultSearchProviderSuggestURL = "https://encrypted.google.com/complete/search?output=chrome&q={searchTerms}";
      # defaultSearchProviderSearchURL = "https://encrypted.google.com/search?q={searchTerms}&{google:RLZ}{google:originalQueryForSuggestion}{google:assistedQueryStats}{google:searchFieldtrialParameter}{google:searchClient}{google:sourceId}{google:instantExtendedEnabledParameter}ie={inputEncoding}";
      enable = true;
      extensions = import ./chrome-extensions.nix;
      extraOpts = {
        # "BrowserSignin" = 0;
        "WelcomePageOnOSUpgradeEnabled" = false;
        # "SyncDisabled" = true;
        # "PasswordManagerEnabled" = false;
        "DefaultBrowserSettingEnabled" = false;
        "SpellcheckEnabled" = true;
        "SpellcheckLanguage" = [
          "fr-FR"
          "en-US"
          "ro"
        ];
        # "JavascriptEnabled" = false;
        # "ManagedBookmarks" = [
        #   { name = "example.com"; url = "https://example.com"; }
        # ];
      };
    };
 }
