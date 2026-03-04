# Update yt-dlp to fix YouTube challenge solver breakage
inputs: final: prev: {
  yt-dlp = prev.yt-dlp.overrideAttrs (old: {
    version = "2026.03.03";
    src = prev.fetchFromGitHub {
      owner = "yt-dlp";
      repo = "yt-dlp";
      rev = "2026.03.03";
      hash = "sha256-BPZzMT1IrZvgva/m5tYMaDYoUaP3VmpmcYeOUOwuoUY=";
    };
    postPatch = builtins.replaceStrings
      [ "if curl_cffi_version != (0, 5, 10) and not (0, 10) <= curl_cffi_version < (0, 14)" ]
      [ "if curl_cffi_version != (0, 5, 10) and not (0, 10) <= curl_cffi_version < (0, 15)" ]
      old.postPatch;
  });
}
