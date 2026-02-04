{ ... }:
{
  programs.chromium.enable = true;
  programs.chromium.extraOpts = {
    JavaScriptBlockedForUrls = [
      "[*.]onion"
    ];
  };
}
