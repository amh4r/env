-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Copy the focused file's relative path to the system clipboard
vim.keymap.set("n", "<localleader>y", function()
  local path = vim.fn.fnamemodify(vim.fn.expand("%"), ":.")
  vim.fn.setreg("+", path)
  vim.notify("Copied: " .. path)
end, { desc = "Copy relative path" })

-- Cmd+C: yank visual selection to system clipboard.
-- Ghostty sends esc:c (Alt+c) for super+c, which nvim sees as <M-c>.
vim.keymap.set("v", "<M-c>", '"+ygv', { noremap = true, silent = true })

-- Reveal the current file in Finder
vim.keymap.set("n", "<leader>fO", function()
  local filepath = vim.fn.expand("%:p")
  vim.fn.system({ "open", "-R", filepath })
end, { desc = "Reveal in Finder" })

-- Side-by-side diff of current file against index (toggle)
vim.keymap.set("n", "<leader>g0", function()
  if vim.wo.diff then
    vim.cmd("diffoff!")
    vim.cmd("only")
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_get_name(buf):match("^gitsigns://") then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
  else
    require("gitsigns").diffthis()
  end
end, { desc = "Diff This" })
