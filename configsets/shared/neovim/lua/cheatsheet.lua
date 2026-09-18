-- A tabbed floating window listing the keymaps I keep forgetting.
-- <leader>h toggles it.

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
