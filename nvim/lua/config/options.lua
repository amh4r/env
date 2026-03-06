-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- Treat MDX files as markdown for better LSP support
vim.filetype.add({
  extension = {
    mdx = "markdown",
  },
})

-- Prefer .git root over LSP root for project detection
vim.g.root_spec = { { ".git", "lua" }, "lsp", "cwd" }

-- Keep default register separate from system clipboard.
-- Use "+y / "+p to explicitly access the system clipboard.
vim.opt.clipboard = ""

-- Auto-reload files changed outside of nvim
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  command = "silent! checktime",
})
local timer = vim.uv.new_timer()
timer:start(
  0,
  1000,
  vim.schedule_wrap(function()
    pcall(vim.cmd, "silent! checktime")
  end)
)
