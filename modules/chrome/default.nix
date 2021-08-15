{
  security.chromiumSuidSandbox.enable = true;
  programs.chromium = {
      # homepageLocation = "https://www.google.com";
      # defaultSearchProviderSuggestURL = "https://encrypted.google.com/complete/search?output=chrome&q={searchTerms}";
      # defaultSearchProviderSearchURL = "https://encrypted.google.com/search?q={searchTerms}&{google:RLZ}{google:originalQueryForSuggestion}{google:assistedQueryStats}{google:searchFieldtrialParameter}{google:searchClient}{google:sourceId}{google:instantExtendedEnabledParameter}ie={inputEncoding}";
      enable = true;
      extensions = [
        "adelhekhakakocomdfejiipdnaadiiib" # Text Mode
        "bkegjcmidjgnmjbeninfbhoaelblpgic" # Plain Text Linker
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
        "dhdgffkkebhmkfjojejmpbldmpobfkfo" # Tampermonkey
        "dneaehbmnbhcippjikoajpoabadpodje" # Old Reddit Redirect
        "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
        "fpnmgdkabkmnadcjpehmlllkndpkmiak" # Wayback Machine
        "gneobebnilffgkejpfhlgkmpkipgbcno" # Death To _blank
        "hahklcmnfgffdlchjigehabfbiigleji" # Play with MPV
        "hdokiejnpimakedhajhdlcegeplioahd" # LastPass: Free Password Manager
        "hkgfoiooedgoejojocmhlaklaeopbecg" # Picture-in-Picture Extension (by Google)
        "igiofjhpmpihnifddepnpngfjhkfenbp" # AutoPagerize
        "jchobbjgibcahbheicfocecmhocglkco" # Neat URL
        "jeogkiiogjbmhklcnbgkdcjoioegiknm" # Slack
        "mgijmajocgfcbeboacabfgobmjgjcoja" # Google Dictionary (by Google)
        "mmcgnaachjapbbchcpjihhgjhpfcnoan" # Open New Tab After Current Tab
        "ncppfjladdkdaemaghochfikpmghbcpc" # Open-as-Popup
        "nffaoalbilbmmfgbnbgppjihopabppdk" # Video Speed Controller
        "nlnkcinjjeoojlhdiedbbolilahmnldj" # Tab Sorter
        "pgdnlhfefecpicbbihgmbmffkjpaplco" # uBlock Origin Extra
        "pkedcjkdefgpdelpbcmbmeomcjbeemfm" # Chrome Media Router
        "padekgcemlokbadohgkifijomclgjgif" # Proxy SwitchyOmega
        # "jlkpnekpomdbobkdokohimfcbgcpldfp" # QuickBlock
        "lpcaedmchfhocbbapmcbpinfpgnhiddi" # Google Keep Chrome Extension
        "fihnjjcciajhdojfnbdddfaoknhalnja" # I don't care about cookies
        "iipjdmnoigaobkamfhnojmglcdbnfaaf" # Clutter Free - Prevent duplicate tabs
        "gkmndgjgpolmikgnipipfekglbbgjcel" # AutoHideDownloadsBar
        # "hfjbmagddngcpeloejdejnfgbamkjaeg" # Vimium C - All by Keyboard
      ];
      extraOpts = {
        # "BrowserSignin" = 0;
        "WelcomePageOnOSUpgradeEnabled" = false;
        # "SyncDisabled" = true;
        # "PasswordManagerEnabled" = false;
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
