-- Scrollbar with git change and diagnostic markers
return {
  {
    "petertriho/nvim-scrollbar",
    dependencies = {
      "lewis6991/gitsigns.nvim",
    },
    opts = {
      handle = {
        -- Semi-transparent cursor position indicator
        blend = 50,
      },
      -- Thin bar for all git change types
      marks = {
        GitAdd = { text = "▎" },
        GitChange = { text = "▎" },
        GitDelete = { text = "▎" },
      },
    },
    config = function(_, opts)
      require("scrollbar").setup(opts)

      -- Add git markers
      require("scrollbar.handlers.gitsigns").setup()
    end,

    -- Load lazily to avoid startup overhead, but after UI init so it's always visible
    event = "VeryLazy",

    keys = {
      -- Toggle: flips `config.show` then forces a re-render or clear
      {
        "<leader>um",
        function()
          local config = require("scrollbar.config")
          local scrollbar = require("scrollbar")
          local current = config.get()
          if current.show then
            config.set({ show = false })
            scrollbar.clear()
          else
            config.set({ show = true })
            scrollbar.render()
          end
        end,
        desc = "Toggle Scrollbar",
      },
    },
  },
}
