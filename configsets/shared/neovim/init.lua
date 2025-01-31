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

-- Set vim leader key to space
-- Still not convinced about this one
vim.g.mapleader = " "

-- Set plugins for lazy to install
require("lazy").setup({
  { 'projekt0n/github-nvim-theme' },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { 'nvim-lua/plenary.nvim' }
  },
  "tpope/vim-sleuth"
})

-- Set colorscheme
vim.cmd.colorscheme("github_light_colorblind")

-- Nvim Telescope
local builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

-- DOWN WITH THE MOUSE
vim.opt.mouse = nil

-- Make haml files easier to read
vim.opt.cursorcolumn = true
vim.opt.cursorline = true

-- Keep cursor from bashing into the side of the window
vim.opt.scrolloff = 5

-- Vinegar but less
vim.keymap.set('n', '-', '<cmd>Ex<cr>', {})
vim.g.netrw_banner = 0

-- Notes!
-- Usage:
-- <leader>n -> opens notes folder
-- 
-- <leader>N -> sets current primary notes folder
--
-- _ -> Toggles between current file and notes folder, similar to C+^
-- If the notes file isn't set, it won't do anything. It also has strict rules on jumping
local notes_file = ''
local return_file = ''

vim.keymap.set('n', '<leader>n', '<cmd>Tex ~/notes<cr>')
vim.keymap.set('n', '_', function()
  local current_file = vim.fn.expand('%:p')

  if return_file ~= '' then -- We don't want to allow jumping from another buffer back to the previous file
    if current_file ~= notes_file then
      print("Cannot jump from " .. current_file .. " to " .. return_file)
    else
      vim.cmd.edit(return_file)
      print("Returned to: " .. return_file)
      return_file = ''
    end
  elseif notes_file ~= '' then -- We don't want to allow jumping from the notes file to the notes file
    if current_file == notes_file then
      print("Cannot jump from " .. notes_file .. " to " .. notes_file)
    else
      return_file = vim.fn.expand('%:p')
      vim.cmd.edit(notes_file)
      print("Opened note: " .. notes_file)
    end
  else
    vim.cmd.Tex('~/notes')
    print("Notes file is not set <leader>N")
  end
end)

vim.keymap.set('n', '<leader>N', function()
  notes_file = vim.fn.expand('%:p')

  print("Set notes file to: " .. notes_file)
end)

local notes = '/Users/calebowens/notes'

vim.api.nvim_create_autocmd({'BufEnter', 'BufWinEnter'}, {
  pattern = {'*.md'},
  callback = function(ev)
    -- Prevent file being set twice and printing message twice. I'm sure there is a way of tracking this without this problem
    -- I don't want to keep overwriting the notes file. Presumibly, the first one I open, is the project one, and further visits
    -- are just peeking at notes from other projects
    if string.sub(ev['file'], 1, #notes) == notes and notes_file ~= ev['file'] and notes_file == '' then
      notes_file = ev['file']
      print("Set notes file to: " .. notes_file)
    end
  end
})

vim.keymap.set('n', '<leader>t', function()
  current_line = vim.api.nvim_get_current_line()
  print(current_line)

  if string.find(current_line, '- %[ %] ') ~= nil then
    current_line = string.gsub(current_line, '- %[ %] ', '- %[x%] ', 1)
    vim.api.nvim_set_current_line(current_line)
    print('Marked done!')
  elseif string.find(current_line, '- %[x%] ') ~= nil then
    current_line = string.gsub(current_line, '- %[x%] ', '- ', 1)
    vim.api.nvim_set_current_line(current_line)
    print('Marked bullet')
  elseif string.find(current_line, '- ') ~= nil then
    current_line = string.gsub(current_line, '- ', '- %[ %] ', 1)
     vim.api.nvim_set_current_line(current_line)
    print('Marked todo')
  else
    print('Bullet not found')
  end
end)

-- Fancy moving of lines
vim.keymap.set('n', '<C-k>', '<cmd>m -2<cr>')
vim.keymap.set('n', '<C-j>', '<cmd>m +1<cr>')
vim.keymap.set('n', '<C-h>', '<<')
vim.keymap.set('n', '<C-l>', '>>')
vim.keymap.set('v', '<C-k>', 'dkP`[V`]')
vim.keymap.set('v', '<C-j>', 'dp`[V`]')
vim.keymap.set('v', '<C-h>', '<`[V`]')
vim.keymap.set('v', '<C-l>', '>`[V`]')

-- Swapfile settings
-- This may be bad, but I want to open the same files in multiple vim instances
-- (which is also supposed to be bad) so we'll see how this goes
vim.opt.swapfile = false
vim.opt.backup = false

-- Xray eyes!
vim.opt.list = true

-- Peace!
vim.keymap.set('n', '<leader>x', '<cmd>tabonly|%bd|e#<cr>')

-- Show me where the lines are!
vim.opt.colorcolumn = '80'

-- Standardrb
vim.opt.signcolumn = "no" -- otherwise it bounces in and out, not strictly needed though
vim.api.nvim_create_autocmd("FileType", {
  pattern = "ruby",
  group = vim.api.nvim_create_augroup("RubyLSP", { clear = true }), -- also this is not /needed/ but it's good practice 
  callback = function()
    vim.lsp.start {
      name = "standard",
      cmd = { "sherman_standardrb", "--lsp" },
    }
  end,
})

-- Making my terninal look cooler
vim.opt.laststatus = 1

-- Wrap markdown and comments at ~~120~~ columns
-- 80 is the new 120
vim.opt.textwidth = 80
