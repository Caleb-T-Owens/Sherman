-- Set colorscheme
local function sync_theme()
  vim.cmd.colorscheme("github_" .. vim.o.background .. "_colorblind")
end

sync_theme()
vim.api.nvim_create_autocmd("OptionSet", {
  pattern = "background",
  callback = sync_theme,
})

-- Nvim Telescope
local builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

vim.opt.signcolumn = "no"

-- DOWN WITH THE MOUSE
vim.opt.mouse = ""

-- Make haml files easier to read
vim.opt.cursorcolumn = true
vim.opt.cursorline = true

-- Keep cursor from bashing into the side of the window
vim.opt.scrolloff = 5

-- Vinegar but less
vim.keymap.set('n', '-', '<cmd>Ex<cr>', {})
vim.g.netrw_banner = 0

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
-- vim.opt.colorcolumn = '80'
-- Wrap markdown and comments at ~~120~~ columns
vim.opt.textwidth = 80
-- Tabs should be 4 characteres
vim.opt.tabstop = 4

-- Making my terninal look cooler
vim.opt.laststatus = 1

-- Please go away F1 help screen
vim.keymap.set({'v', 'n', 'i'}, '<F1>', '<Esc>')
