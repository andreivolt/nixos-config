-- Shared base config for pager-like nvim sessions
-- Used by both kitty-scrollback and standalone pager

vim.opt.signcolumn = "no"
vim.opt.statuscolumn = ""
vim.opt.clipboard = "unnamedplus"
vim.opt.wrap = true
vim.opt.number = false
vim.opt.relativenumber = false
vim.opt.cursorline = true
vim.opt.mouse = "a"
vim.opt.termguicolors = true

-- Bootstrap lazy.nvim (shared with main nvim config)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local nvim_lua = vim.fn.expand("~/.config/nvim/lua")
if (vim.uv or vim.loop).fs_stat(lazypath) and (vim.uv or vim.loop).fs_stat(nvim_lua) then
  vim.opt.rtp:prepend(lazypath)
  vim.opt.rtp:prepend(vim.fn.expand("~/.config/nvim"))
  require("lazy").setup({
    spec = { import = "plugins.colorscheme-aurora" },
    defaults = { lazy = false },
    change_detection = { enabled = false },
    install = { missing = false },
    rocks = { enabled = false },
  })
  -- Load colorscheme customizations
  pcall(dofile, vim.fn.expand("~/.config/nvim/lua/user/colorscheme.lua"))
else
  pcall(vim.cmd, "colorscheme default")
end

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank({ timeout = 100 })
  end,
})

-- q to quit
vim.keymap.set("n", "q", "<cmd>q<cr>", { silent = true })
