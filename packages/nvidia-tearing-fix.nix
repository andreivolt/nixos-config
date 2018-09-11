self: super: with super; {

nvidia-tearing-fix = writeShellScriptBin "nvidia-tearing-fix" ''
  nvidia-settings --assign CurrentMetaMode='\
    DP-0: nvidia-auto-select +0+0 {ForceCompositionPipeline=On}, \
    DP-2: nvidia-auto-select +0+0 {ForceCompositionPipeline=On, SameAs=DP-0}' '';

}
