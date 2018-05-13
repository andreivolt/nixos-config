{ config, pkgs, ... }:

{
  services.xserver.xrandrHeads = let
    withNvidiaTearingFix = { position, rotation ? "normal" }: ''
      Option "metamodes" "nvidia-auto-select ${position} {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On, Rotate=${rotation}}"
      Option "AllowIndirectGLXProtocol" "off"
      Option "TripleBuffer" "on"
    '';

    leftMonitor = {
      output = "DP-2";
      monitorConfig = ''
        # ${withNvidiaTearingFix { position = "+2160+0"; rotation = "left"; }}
        Option "Rotate" "left"
        Option "LeftOf" "DP-4"
      '';
    };

    centerMonitor = {
      output = "DP-4";
      primary = true;
      # monitorConfig = withNvidiaTearingFix { position = "+3840+2160"; };
    };

    rightMonitor = {
      output = "DP-0";
      # monitorConfig = withNvidiaTearingFix { position = "+3840+0"; };
      monitorConfig = ''
        Option "Above" "DP-4"
      '';
    };

  in [ leftMonitor centerMonitor rightMonitor ];
}
