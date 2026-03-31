return {
  {
    dir = "~/personal/indifferent.nvim",
    name = "indifferent.nvim",
    dependencies = { "MunifTanjim/nui.nvim", "sindrets/diffview.nvim" },
    keys = {
      { "<leader>gc", function() require("indifferent").toggle() end, desc = "Indifferent (compare)" },
      { "<leader>gq", function() require("indifferent").close_diff() end, desc = "Close diff" },
    },
  },
}
