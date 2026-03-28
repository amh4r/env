local M = {}

function M.toggle()
  require("git-versus.panel").toggle()
end

function M.open()
  require("git-versus.panel").open()
end

function M.close()
  require("git-versus.panel").close()
end

function M.close_diff()
  local scratch_wins = {}
  local restore_win = nil
  local restore_buf = nil

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local ok, marked = pcall(vim.api.nvim_win_get_var, win, "git_versus_diff")
      if ok and marked then
        local buf = vim.api.nvim_win_get_buf(win)
        local name = vim.api.nvim_buf_get_name(buf)
        if name:match("^git%-versus://") then
          table.insert(scratch_wins, { win = win, buf = buf })
        else
          -- This is the main window; check if it has a buffer to restore
          restore_win = win
          local rok, rbuf = pcall(vim.api.nvim_win_get_var, win, "git_versus_restore_buf")
          if rok and rbuf and vim.api.nvim_buf_is_valid(rbuf) then
            restore_buf = rbuf
          end
        end
      end
    end
  end

  -- Close scratch windows and delete their buffers
  for _, s in ipairs(scratch_wins) do
    if vim.api.nvim_win_is_valid(s.win) then
      vim.api.nvim_win_close(s.win, true)
    end
    if vim.api.nvim_buf_is_valid(s.buf) then
      vim.api.nvim_buf_delete(s.buf, { force = true })
    end
  end

  -- Restore the main window's original buffer and clean up the diff file buffer
  if restore_win and vim.api.nvim_win_is_valid(restore_win) then
    local diff_buf = vim.api.nvim_win_get_buf(restore_win)
    vim.api.nvim_set_option_value("diff", false, { win = restore_win })
    if restore_buf then
      vim.api.nvim_win_set_buf(restore_win, restore_buf)
    end
    -- Delete the file buffer that was opened for the diff
    if diff_buf ~= restore_buf and vim.api.nvim_buf_is_valid(diff_buf) then
      vim.api.nvim_buf_delete(diff_buf, { force = true })
    end
    vim.api.nvim_win_del_var(restore_win, "git_versus_diff")
    pcall(vim.api.nvim_win_del_var, restore_win, "git_versus_restore_buf")
  end
end

return M
