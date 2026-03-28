return {
  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    keys = {
      { "<leader>sg", "<cmd>GrugFar<cr>", desc = "Search (grug-far)" },
    },
    config = function()
      require("grug-far").setup({
        windowCreationCommand = "rightbelow vsplit",
      })
    end,
  },
}
