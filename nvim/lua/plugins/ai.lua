return {
  -- Disable Copilot
  { "zbirenbaum/copilot.lua", enabled = false },

  -- Supermaven
  {
    "supermaven-inc/supermaven-nvim",
    event = "BufReadPost",
    opts = {
      keymaps = {
        accept_suggestion = "<Tab>",
        clear_suggestion = "<C-]>",
        accept_word = "<C-j>",
      },
    },
  },
}
