{ lib, ... }:

with lib;

{
  services.xserver.screenSection = mkAfter ''
    Option "metamodes" "DP-0: nvidia-auto-select +0+0 { ForceCompositionPipeline=On }, DP-2: nvidia-auto-select +0+0 { ForceCompositionPipeline=On, SameAs=DP-0 }"
    Option "AllowIndirectGLXProtocol" "off"
    Option "TripleBuffer" "on" '';
}
