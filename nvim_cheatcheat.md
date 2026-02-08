# NVIM cheatcheat

## LSP Specific

- "gra" (Normal and Visual mode) is mapped to vim.lsp.buf.code_action()
- "gri" is mapped to vim.lsp.buf.implementation()
- "grn" is mapped to vim.lsp.buf.rename()
- "grr" is mapped to vim.lsp.buf.references()
- "grt" is mapped to vim.lsp.buf.type_definition()
- "gO" is mapped to vim.lsp.buf.document_symbol()
- "TRL-S (Insert mode) is mapped to vim.lsp.buf.signature_help()
- "an" and "in" (Visual and Operator-pending mode) are mapped to outer and inner incremental selections, respectively, using vim.lsp.buf.selection_range()

Not entirly LSP specific, but related enough

- ctrl+] jumps to definition

## Diagnostics

These are unhinged and might warrnet changing

- ]d jumps to the next diagnostic in the buffer. ]d-default
- [d jumps to the previous diagnostic in the buffer. [d-default
- ]D jumps to the last diagnostic in the buffer. ]D-default
- [D jumps to the first diagnostic in the buffer. [D-default
- <C-w>d shows diagnostic at cursor in a floating window. CTRL-W_d-default

## Navigation

- ctrl-i and ctrl-o seem to go up and down the buffers list
- ctrl-t nagivates back throuch 
