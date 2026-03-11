local function diff_open_prompt()
  vim.ui.input({ prompt = "Diff against: ", default = "origin/main" }, function(ref)
    if ref and ref ~= "" then
      vim.cmd("DiffviewOpen " .. ref)
    end
  end)
end

return {
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    keys = {
      { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Diffview against HEAD" },
      { "<leader>gm", diff_open_prompt, desc = "Diffview against ref" },
      { "<leader>gV", "<cmd>DiffviewClose<cr>", desc = "Close Diffview" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history (current)" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "File history (branch)" },
    },
    opts = {
      view = {
        default = { layout = "diff2_horizontal" },
      },
      keymaps = {
        -- Use <leader>e to toggle the file tree (same as the explorer).
        view = {
          { "n", "<leader>e", function() require("diffview.actions").toggle_files() end, { desc = "Toggle file tree" } },
        },
        file_panel = {
          { "n", "<leader>e", function() require("diffview.actions").toggle_files() end, { desc = "Toggle file tree" } },
        },
      },
    },
  },
}
