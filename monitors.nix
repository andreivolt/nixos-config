with services.xserver; {
  xrandrHeads =
  let withNvidiaTearingFix = { position, rotation ? "normal" }: ''
    Option "metamodes" "nvidia-auto-select ${position} {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On, Rotate=${rotation}}"
    Option "AllowIndirectGLXProtocol" "off"
    Option "TripleBuffer" "on"
    ''; in [
    {
      output = "DP-2";
      monitorConfig = ''
      ${withNvidiaTearingFix { position = "+2160+0"; rotation = "left"; }}
      Option "Rotate" "left"
      '';
    }
    {
      output = "DP-4";
      primary = true;
      monitorConfig = withNvidiaTearingFix { position = "+3840+2160"; };
    }
    {
      output = "DP-0";
      monitorConfig = withNvidiaTearingFix { position = "+3840+0"; };
    }
  ];
};
