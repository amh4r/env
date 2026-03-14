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
    config = function(_, opts)
      -- Soften the deleted-line filler blocks (the red/white striped regions).
      -- Setting fg = bg hides the diagonal stripe characters.
      vim.api.nvim_set_hl(0, "DiffviewDiffDeleteDim", { bg = "#3a1e1e" })
      vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#3a1e1e", fg = "#3a1e1e" })
      require("diffview").setup(opts)
    end,
    opts = {
      view = {
        default = { layout = "diff2_horizontal" },
      },
      keymaps = {
        view = {
          -- Use <leader>e to toggle the file tree (same as the explorer).
          {
            "n",
            "<leader>e",
            function()
              require("diffview.actions").toggle_files()
            end,
            { desc = "Toggle file tree" },
          },

          -- Use R to refresh the view.
          { "n", "R", "<cmd>DiffviewRefresh<cr>", { desc = "Refresh" } },
        },
        file_panel = {
          -- Use <leader>e to toggle the file tree (same as the explorer).
          {
            "n",
            "<leader>e",
            function()
              require("diffview.actions").toggle_files()
            end,
            { desc = "Toggle file tree" },
          },
          { "n", "R", "<cmd>DiffviewRefresh<cr>", { desc = "Refresh" } },
        },
      },
    },
  },
}
