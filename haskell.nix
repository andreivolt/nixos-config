{ pkgs, lib, ... }:

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
    "brittany/config.yaml".text = lib.generators.toYAML {} {
      conf_debug = {
        dconf_dump_annotations = false;
        dconf_dump_ast_full = false;
        dconf_dump_ast_unknown = false;
        dconf_dump_bridoc_final = false;
        dconf_dump_bridoc_raw = false;
        dconf_dump_bridoc_simpl_alt = false;
        dconf_dump_bridoc_simpl_columns = false;
        dconf_dump_bridoc_simpl_floating = false;
        dconf_dump_bridoc_simpl_indent = false;
        dconf_dump_bridoc_simpl_par = false;
        dconf_dump_config = false;
        dconf_roundtrip_exactprint_only = false;
      };
      conf_errorHandling = {
        econf_ExactPrintFallback = "ExactPrintFallbackModeInline";
        econf_Werror = false;
        econf_omit_output_valid_check = false;
        econf_produceOutputOnErrors = false;
      };
      conf_forward = {
        options_ghc = [];
      };
      conf_layout = "lconfig_a";
      conf_preprocessor = {
        ppconf_CPPMode = "CPPModeAbort";
        ppconf_hackAroundIncludes = false;
      };
      conf_version = 1;
    };
  };

  home-manager.users.avo.programs.zsh.shellAliases = {
    stack = "${pkgs.stack}/bin/stack --nix";
  };

  home-manager.users.avo.home.file = {
    ".ghci".text = ''
      :set prompt "λ "
    '';


    ".stylish-yaskell.yaml".text = lib.generators.toYAML {} {
      columns = 80;
      newline = "native";
      steps = [
        {
          simple_align = {
            cases = true;
            records = true;
            top_level_patterns = true;
          };
        }
        {
          imports = {
            align = "global";
            empty_list_align = "inherit";
            list_align = "after_alias";
            list_padding = 4;
            long_list_align = "inline";
            pad_module_names = true;
            separate_lists = true;
            space_surround = false;
          };
        }
        {
          language_pragmas = {
            align = true;
            remove_redundant = true;
            style = "vertical";
          };
        }
        {
          trailing_whitespace = {};
        }
      ];
    };
  };
}
