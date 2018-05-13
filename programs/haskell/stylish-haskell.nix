{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    (haskell.lib.justStaticExecutables haskellPackages.stylish-haskell)
  ];

  home-manager.users.avo
    .xdg.configFile."stylish-yaskell/config.yaml".text = lib.generators.toYAML {} {
      columns = 80;
      newline = "native";
      steps = [
        {
          simple_align = {
            cases              = true;
            records            = true;
            top_level_patterns = true;
          };
        }
        {
          imports = {
            align            = "global";
            empty_list_align = "inherit";
            list_align       = "after_alias";
            list_padding     = 4;
            long_list_align  = "inline";
            pad_module_names = true;
            separate_lists   = true;
            space_surround   = false;
          };
        }
        {
          language_pragmas = {
            align            = true;
            remove_redundant = true;
            style            = "vertical";
          };
        }
        {
          trailing_whitespace = {};
        }
      ];
    };
}
