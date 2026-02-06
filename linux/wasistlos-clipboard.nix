# WORKAROUND: WebKitGTK's legacy paste event exposes empty clipboardData.items
# for images, but the Async Clipboard API works fine. This patches WasIstLos to
# load a JS polyfill that bridges the two, enabling image paste in WhatsApp Web.
# Remove this file when upstream fixes it.
{ ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      wasistlos = prev.wasistlos.overrideAttrs (old: {
        patches = (old.patches or []) ++ [
          (builtins.toFile "wasistlos-clipboard.patch" ''
            --- a/src/ui/WebView.cpp
            +++ b/src/ui/WebView.cpp
            @@ -212,6 +212,7 @@
                     webkit_settings_set_enable_developer_extras(settings, TRUE);
                     auto hwAccelPolicy = static_cast<WebKitHardwareAccelerationPolicy>(util::Settings::getInstance().getValue<int>("web", "hw-accel", 1));
                     webkit_settings_set_hardware_acceleration_policy(settings, hwAccelPolicy);
            +        webkit_settings_set_javascript_can_access_clipboard(settings, TRUE);
                     webkit_settings_set_minimum_font_size(settings, util::Settings::getInstance().getValue<int>("web", "min-font-size", 0));

                     webkit_web_view_set_zoom_level(*this, util::Settings::getInstance().getValue<double>("general", "zoom-level", 1.0));
            @@ -221,6 +222,23 @@
                         applyCustomCss(cssFilePath);
                     }

            +        // Load clipboard polyfill userscript if present
            +        {
            +            auto jsPath = configDir + "/" + WIL_NAME + "/clipboard-polyfill.js";
            +            std::ifstream jsFile(jsPath);
            +            if (jsFile.good())
            +            {
            +                std::string js((std::istreambuf_iterator<char>(jsFile)),
            +                                std::istreambuf_iterator<char>());
            +                auto* script = webkit_user_script_new(
            +                    js.c_str(), WEBKIT_USER_CONTENT_INJECT_TOP_FRAME,
            +                    WEBKIT_USER_SCRIPT_INJECT_AT_DOCUMENT_START, nullptr, nullptr);
            +                auto* manager = webkit_web_view_get_user_content_manager(*this);
            +                webkit_user_content_manager_add_script(manager, script);
            +                webkit_user_script_unref(script);
            +            }
            +        }
            +
                     webkit_web_view_load_uri(*this, WHATSAPP_WEB_URI);
                 }

          '')
        ];
      });
    })
  ];

  home-manager.sharedModules = [{
    xdg.configFile."wasistlos/clipboard-polyfill.js".text = ''
      document.addEventListener('paste', async function(e) {
        if (e.clipboardData.items.length > 0) return;
        try {
          var items = await navigator.clipboard.read();
          for (var ci of items) {
            for (var type of ci.types) {
              if (!type.startsWith('image/')) continue;
              var blob = await ci.getType(type);
              var file = new File([blob], 'image.png', {type: type});
              var dt = new DataTransfer();
              dt.items.add(file);
              var ev = new ClipboardEvent('paste', {clipboardData: dt, bubbles: true});
              e.stopImmediatePropagation();
              e.target.dispatchEvent(ev);
              return;
            }
          }
        } catch(err) { console.log('clipboard polyfill error:', err); }
      }, true);
    '';
  }];
}
