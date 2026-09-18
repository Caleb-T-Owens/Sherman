-- General LSP

local builtin = require('telescope.builtin')
local actions = require('telescope.actions')

vim.opt.completeopt = { 'menuone', 'noselect', 'fuzzy', 'popup' }

local completion_group = vim.api.nvim_create_augroup('lsp_completion', { clear = true })
local completion_timer
local completion_request = 0

local function request_completion()
  completion_request = completion_request + 1
  local request = completion_request

  if completion_timer then
    if not completion_timer:is_closing() then
      completion_timer:stop()
      completion_timer:close()
    end
    completion_timer = nil
  end

  if vim.v.char ~= '.' and vim.fn.match(vim.v.char, '^\\k$') == -1 then
    return
  end

  local buffer = vim.api.nvim_get_current_buf()
  vim.schedule(function()
    if request ~= completion_request or vim.api.nvim_get_current_buf() ~= buffer then
      return
    end

    local cursor = vim.api.nvim_win_get_cursor(0)
    local changedtick = vim.b[buffer].changedtick

    completion_timer = vim.defer_fn(function()
      if request ~= completion_request
          or not vim.api.nvim_buf_is_valid(buffer)
          or vim.api.nvim_get_current_buf() ~= buffer
          or vim.api.nvim_get_mode().mode:sub(1, 1) ~= 'i'
          or vim.b[buffer].changedtick ~= changedtick then
        return
      end

      local current_cursor = vim.api.nvim_win_get_cursor(0)
      if current_cursor[1] == cursor[1] and current_cursor[2] == cursor[2] then
        vim.lsp.completion.get()
      end
    end, 100)
  end)
end

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))
    if client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf)
      vim.api.nvim_clear_autocmds({ group = completion_group, buffer = ev.buf })
      vim.api.nvim_create_autocmd('InsertCharPre', {
        group = completion_group,
        buffer = ev.buf,
        callback = request_completion,
      })
    end
  end,
})

-- <leader>l pops a menu of the LSP jumps next to the cursor.  Lowercase opens
-- the result in a new tab, uppercase in the current window.  Muscle memory
-- still works: typing <leader>ld quickly is read straight out of the typeahead,
-- so the menu never gets in the way.

local function pick(picker, in_tab)
  picker({
    jump_type = 'never',
    -- Without the override telescope opens the selection in the current window.
    attach_mappings = in_tab and function()
      actions.select_default:replace(actions.select_tab)
      return true
    end or nil,
  })
end

local function goto_definition(open)
  vim.lsp.buf.definition({
    on_list = function(options)
      -- More than one candidate: hand it to telescope to disambiguate.  This
      -- re-issues the request, which beats rebuilding a picker by hand.
      if #options.items > 1 then
        return pick(builtin.lsp_definitions, open == 'tabedit')
      end

      -- Guard against ':edit' on the current file, which fails with E37 when
      -- the buffer is modified.  A new tab always wants the command.
      local item = options.items[1]
      if open == 'tabedit' or item.filename ~= vim.api.nvim_buf_get_name(0) then
        vim.cmd[open]({ item.filename, magic = { file = false, bar = false } })
      end
      vim.api.nvim_win_set_cursor(0, { item.lnum, item.col - 1 })
      vim.cmd('normal! zv')
    end,
  })
end

local lsp_actions = {
  d = function() goto_definition('tabedit') end,
  D = function() goto_definition('edit') end,
  r = function() pick(builtin.lsp_references, true) end,
  R = function() pick(builtin.lsp_references, false) end,
  i = function() pick(builtin.lsp_implementations, true) end,
  I = function() pick(builtin.lsp_implementations, false) end,
}

local lsp_menu = {
  'd/D  definition',
  'r/R  references',
  'i/I  implementations',
  '',
  'lower: new tab · UPPER: here',
}

vim.keymap.set('n', '<leader>l', function()
  local width = 0
  for _, line in ipairs(lsp_menu) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end

  local buffer = vim.api.nvim_create_buf(false, true)
  vim.bo[buffer].bufhidden = 'wipe'
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lsp_menu)

  local window = vim.api.nvim_open_win(buffer, false, {
    relative = 'cursor',
    row = 1,
    col = 0,
    width = width,
    height = #lsp_menu,
    style = 'minimal',
    border = 'rounded',
  })

  vim.cmd('redraw')
  local ok, key = pcall(vim.fn.getcharstr) -- raises on <C-c>
  if vim.api.nvim_win_is_valid(window) then
    vim.api.nvim_win_close(window, true)
  end

  if ok and lsp_actions[key] then
    lsp_actions[key]()
  end
end, { desc = 'LSP jumps' })

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
-- Neovim already maps .ts/.tsx/.js/.jsx/.mjs/.cjs/.mts/.cts/.json to these
-- filetypes, so there's nothing to add — just tell the server which ones it owns.

vim.lsp.config["ts_ls"] = {
  cmd = { "bun", "x", "typescript-language-server", "--stdio" },
  filetypes = {
    "typescript",
    "typescriptreact",
    "javascript",
    "javascriptreact",
    "json", -- The TS language server can also serve json
  },
  root_markers = { "package.json" },
}

vim.lsp.enable("ts_ls")

-- Haskell
-- The wrapper picks the hls build matching the project's GHC, so it's the one
-- to launch rather than haskell-language-server itself.

vim.lsp.config["hls"] = {
  cmd = { "haskell-language-server-wrapper", "--lsp" },
  filetypes = { "haskell", "lhaskell" },
  -- vim.fs.root doesn't glob, so a bare `foo.cabal` package can't be a marker —
  -- .git is the fallback root for those.
  root_markers = { { "hie.yaml", "cabal.project", "stack.yaml", "package.yaml" }, ".git" },
}

vim.lsp.enable("hls")

-- Treesitter

local treesitter = require('nvim-treesitter')
treesitter.install { 'rust', 'typescript', 'javascript', 'json', 'toml', 'svelte', 'html', 'css', 'haskell' }

vim.api.nvim_create_autocmd('FileType', {
  -- These patterns should probably be defined language types, rather than what
  -- nvim-treesitter _thinks_ a language is.
  pattern = { 'rust', 'typescript', 'svelte', 'html', 'css', 'haskell' },
  callback = function() vim.treesitter.start() end,
})
