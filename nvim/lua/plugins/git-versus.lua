return {
  {
    dir = vim.fn.stdpath("config") .. "/lua/git-versus",
    name = "git-versus",
    dependencies = { "MunifTanjim/nui.nvim", "sindrets/diffview.nvim" },
    keys = {
      { "<leader>gc", function() require("git-versus").toggle() end, desc = "Git Versus (compare)" },
      { "<leader>gq", function() require("git-versus").close_diff() end, desc = "Close diff" },
    },
  },
}
