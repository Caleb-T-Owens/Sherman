-- <leader>t cycles the current line: bullet -> todo -> done -> bullet
vim.keymap.set('n', '<leader>t', function()
  local current_line = vim.api.nvim_get_current_line()
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
