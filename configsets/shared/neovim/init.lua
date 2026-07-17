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

-- Set colorscheme
if os.getenv("SHERMAN_THEME") == "dark" then
  vim.cmd.colorscheme("github_dark_colorblind")
else
  vim.cmd.colorscheme("github_light_colorblind")
end

-- Nvim Telescope
local builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

-- Cheatsheet

local cheatsheet_pages = {
  {
    name = 'LSP',
    lines = {
      '# LSP Specific',
      '',
      '- gra (Normal/Visual): Code action',
      '- gri: Go to implementation',
      '- grn: Rename symbol',
      '- grr: List references',
      '- grt: Go to type definition',
      '- gO: List document symbols',
      '- <C-s> (Insert): Signature help',
      '- an / in (Visual/Operator-pending): Outer/inner incremental selection',
      '',
      'Related: <C-]> jumps to definition.',
    },
  },
  {
    name = 'Diagnostics',
    lines = {
      '# Diagnostics',
      '',
      'These defaults are unhinged and might warrant changing.',
      '',
      '- ]d: Next diagnostic',
      '- [d: Previous diagnostic',
      '- ]D: Last diagnostic',
      '- [D: First diagnostic',
      '- <C-w>d: Show diagnostic at cursor',
    },
  },
  {
    name = 'Navigation',
    lines = {
      '# Navigation',
      '',
      '- <C-o>: Move backward through the jumplist',
      '- <C-i>: Move forward through the jumplist',
      '- <C-t>: Move backward through the tag stack after <C-]>',
    },
  },
}

local cheatsheet_win

local function toggle_cheatsheet()
  if cheatsheet_win and vim.api.nvim_win_is_valid(cheatsheet_win) then
    vim.api.nvim_win_close(cheatsheet_win, true)
    cheatsheet_win = nil
    return
  end

  local page = 1
  local buffer = vim.api.nvim_create_buf(false, true)
  local width = math.max(1, math.min(88, vim.o.columns - 4))
  local height = math.max(1, math.min(18, vim.o.lines - 4))

  cheatsheet_win = vim.api.nvim_open_win(buffer, true, {
    relative = 'editor',
    row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    style = 'minimal',
    border = 'rounded',
    title = ' NVIM cheatsheet ',
    title_pos = 'center',
  })

  vim.bo[buffer].bufhidden = 'wipe'
  vim.bo[buffer].filetype = 'markdown'
  vim.wo[cheatsheet_win].wrap = true
  vim.wo[cheatsheet_win].linebreak = true

  local function render()
    local tabs = {}
    for index, item in ipairs(cheatsheet_pages) do
      tabs[index] = index == page and ('[' .. item.name .. ']') or item.name
    end

    local lines = { table.concat(tabs, '  '), string.rep('─', width) }
    vim.list_extend(lines, cheatsheet_pages[page].lines)
    vim.list_extend(lines, { '', 'h/l or Tab/S-Tab: switch tabs · q/Esc: close' })

    vim.bo[buffer].modifiable = true
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
    vim.bo[buffer].modifiable = false
    vim.api.nvim_win_set_cursor(cheatsheet_win, { 3, 0 })
  end

  local function change_page(offset)
    page = (page - 1 + offset) % #cheatsheet_pages + 1
    render()
  end

  local options = { buffer = buffer, silent = true }
  for _, key in ipairs({ 'l', '<Tab>' }) do
    vim.keymap.set('n', key, function() change_page(1) end, options)
  end
  for _, key in ipairs({ 'h', '<S-Tab>' }) do
    vim.keymap.set('n', key, function() change_page(-1) end, options)
  end
  for index = 1, #cheatsheet_pages do
    vim.keymap.set('n', tostring(index), function()
      page = index
      render()
    end, options)
  end
  for _, key in ipairs({ 'q', '<Esc>' }) do
    vim.keymap.set('n', key, function()
      vim.api.nvim_win_close(cheatsheet_win, true)
      cheatsheet_win = nil
    end, options)
  end

  render()
end

vim.keymap.set('n', '<leader>h', toggle_cheatsheet, { desc = 'Open NVIM cheatsheet' })

-- General LSP

vim.opt.signcolumn = "no"

-- Rust

vim.lsp.config["rust_ls"] = {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  root_markers = { "Cargo.toml" }
}

vim.lsp.enable("rust_ls")

-- Svelte

vim.filetype.add({
  extension = {
    svelte = "svelte"
  }
})

vim.lsp.config["svelte_ls"] = {
  cmd = { "bun", "x", "svelte-language-server" },
  filetypes = { "svelte" },
  root_markers = { "package.json" }
}

vim.lsp.enable("svelte_ls")

-- Eslint

vim.lsp.config["eslint_ls"] = {
  cmd = { "bun", "x", "-p", "vscode-langservers-extracted", "vscode-eslint-language-server", "--stdio" },
  filetypes = { "svelte" },
  root_markers = { "package.json" },
}

vim.lsp.enable("eslint_ls")

-- Typescript + friends

vim.filetype.add({
  extension = {
    typescript = "ts",
    typescript = "js",
    typescript = "tsx",
    typescript = "jsx",
    typescript = "mts",
    typescript = "mjs",
    typescript = "cts",
    typescript = "cjs",
    typescript = "json", -- The TS language server can also serve json
  }
})

vim.lsp.config["ts_ls"] = {
  cmd = { "bun", "x", "typescript-language-server", "--stdio" },
  filetypes = { "typescript" },
  root_markers = { "package.json" },
}

vim.lsp.enable("ts_ls")

-- Treesitter

local treesitter = require('nvim-treesitter')
treesitter.install { 'rust', 'typescript', 'javascript', 'json', 'toml', 'svelte', 'html', 'css' }

vim.api.nvim_create_autocmd('FileType', {
  -- These patterns should probably be defined language types, rather than what
  -- nvim-treesitter _thinks_ a language is.
  pattern = { 'rust', 'typescript', 'svelte', 'html', 'css' },
  callback = function() vim.treesitter.start() end,
})

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
-- vim.opt.colorcolumn = '80'
-- Wrap markdown and comments at ~~120~~ columns
vim.opt.textwidth = 80
-- Tabs should be 4 characteres
vim.opt.tabstop = 4

-- Making my terninal look cooler
vim.opt.laststatus = 1

-- Please go away F1 help screen
vim.keymap.set({'v', 'n', 'i'}, '<F1>', '<Esc>')
