{ pkgs, ... }:

{
  environment.systemPackages = (with pkgs.haskellPackages; [
   apply-refact
   brittany
   ghc
   hindent
   hlint
   hoogle
   stack
   stylish-haskell
   #exe = haskell.lib.justStaticExecutables
  ]);

  home-manager.users.avo.xdg.configFile = {
    "brittany/config.yaml".text = ''
      conf_debug:
        dconf_roundtrip_exactprint_only: false
        dconf_dump_bridoc_simpl_par: false
        dconf_dump_ast_unknown: false
        dconf_dump_bridoc_simpl_floating: false
        dconf_dump_config: false
        dconf_dump_bridoc_raw: false
        dconf_dump_bridoc_final: false
        dconf_dump_bridoc_simpl_alt: false
        dconf_dump_bridoc_simpl_indent: false
        dconf_dump_annotations: false
        dconf_dump_bridoc_simpl_columns: false
        dconf_dump_ast_full: false
      conf_forward:
        options_ghc: []
      conf_errorHandling:
        econf_ExactPrintFallback: ExactPrintFallbackModeInline
        econf_Werror: false
        econf_omit_output_valid_check: false
        econf_produceOutputOnErrors: false
      conf_preprocessor:
        ppconf_CPPMode: CPPModeAbort
        ppconf_hackAroundIncludes: false
      conf_version: 1
      conf_layout:
        lconfig_a
    '';
  };

  home-manager.users.avo.home.file = {
    ".stylish-yaskell.yaml".text = ''
      steps:
        - simple_align:
            cases: true
            top_level_patterns: true
            records: true
        - imports:
            align: global
            list_align: after_alias
            pad_module_names: true
            long_list_align: inline
            empty_list_align: inherit
            list_padding: 4
            separate_lists: true
            space_surround: false
        - language_pragmas:
            style: vertical
            align: true
            remove_redundant: true
        - trailing_whitespace: {}
      columns: 80
      newline: native
    '';
  };
}
