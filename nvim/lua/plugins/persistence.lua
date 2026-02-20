return {
  "folke/persistence.nvim",
  lazy = false,
  opts = {},
  init = function()
    vim.api.nvim_create_autocmd("VimEnter", {
      nested = true,
      callback = function()
        -- Only auto-restore when opened with no args (skip if given a file)
        if vim.fn.argc() == 0 then
          -- Restore the per-directory session. All the previously open buffers
          -- will be restored
          require("persistence").load()
          vim.schedule(function()
            -- Close any directory buffers left over in the session. This
            -- prevents directory buffers from appearing when restoring a
            -- session, even though they weren't open when the session was
            -- saved
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
              local name = vim.api.nvim_buf_get_name(buf)
              if name ~= "" and vim.fn.isdirectory(name) == 1 then
                vim.api.nvim_buf_delete(buf, { force = true })
              end
            end

            -- Open the file explorer after restore. Without this, you need to
            -- press <leader>e every time you open nvim
            Snacks.explorer.open()
          end)
        end
      end,
    })
  end,
}
