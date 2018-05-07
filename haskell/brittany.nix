{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs.haskellPackages; [ brittany ];

  home-manager.users.avo
    .xdg.configFile."brittany/config.yaml".text = lib.generators.toYAML {} {
      conf_debug = {
        dconf_dump_annotations           = false;
        dconf_dump_ast_full              = false;
        dconf_dump_ast_unknown           = false;
        dconf_dump_bridoc_final          = false;
        dconf_dump_bridoc_raw            = false;
        dconf_dump_bridoc_simpl_alt      = false;
        dconf_dump_bridoc_simpl_columns  = false;
        dconf_dump_bridoc_simpl_floating = false;
        dconf_dump_bridoc_simpl_indent   = false;
        dconf_dump_bridoc_simpl_par      = false;
        dconf_dump_config                = false;
        dconf_roundtrip_exactprint_only  = false;
      };
      conf_errorHandling = {
        econf_ExactPrintFallback      = "ExactPrintFallbackModeInline";
        econf_Werror                  = false;
        econf_omit_output_valid_check = false;
        econf_produceOutputOnErrors   = false;
      };
      conf_forward = {
        options_ghc = [];
      };
      conf_layout = "lconfig_a";
      conf_preprocessor = {
        ppconf_CPPMode            = "CPPModeAbort";
        ppconf_hackAroundIncludes = false;
      };
      conf_version = 1;
    };
}
