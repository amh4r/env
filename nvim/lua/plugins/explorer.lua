return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            win = {
              list = {
                keys = {
                  -- Don't close on Esc. Use <leader>e to toggle
                  ["<Esc>"] = false,
                },
              },
            },
          },
        },
      },
    },
  },
}
