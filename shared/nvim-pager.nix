# Standalone nvim pager
{pkgs, ...}:
let
  pagerConfig = ''
    dofile(vim.fn.expand("~/.config/nvim-pager.lua"))

    vim.opt.swapfile = false

    -- stdin mode: set nofile buftype (env set by wrapper script)
    if vim.env.NVIM_PAGER_STDIN then
      vim.opt.buftype = "nofile"
      vim.opt.readonly = true
      vim.opt.modifiable = false
    end
  '';

  pagerScript = pkgs.writeShellScriptBin "nvim-pager" ''
    if [ -t 0 ]; then
      exec ${pkgs.neovim}/bin/nvim -R --cmd "set nocompatible" -u ~/.config/nvim-pager/init.lua "$@"
    else
      # Strip ANSI escape codes from stdin before passing to nvim
      export NVIM_PAGER_STDIN=1
      ${pkgs.ansifilter}/bin/ansifilter | exec ${pkgs.neovim}/bin/nvim -R --cmd "set nocompatible" -u ~/.config/nvim-pager/init.lua -
    fi
  '';
in {
  home-manager.sharedModules = [
    (_: {
      home.packages = [ pagerScript ];
      xdg.configFile."nvim-pager.lua".source = ./nvim-pager.lua;
      xdg.configFile."nvim-pager/init.lua".text = pagerConfig;
    })
  ];
}
