-- Set vim leader key to space
-- Still not convinced about this one
vim.g.mapleader = " "

-- Bootstrap lazy.nvim, plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Set plugins for lazy to install
require("lazy").setup({
  { 'projekt0n/github-nvim-theme' },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { 'nvim-lua/plenary.nvim' }
  },
  "tpope/vim-sleuth",
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ':TSUpdate'
  }
})

-- Everything below needs the plugins loaded: editor for the colorscheme and
-- telescope, lsp for telescope.
require("editor")
require("lsp")
require("cheatsheet")
require("notes")
