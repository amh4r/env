-- Persistent bookmarks with sqlite storage, telescope integration, and cross-file navigation
return {
  {
    "LintaoAmons/bookmarks.nvim",
    tag = "3.2.0",
    dependencies = {
      { "kkharji/sqlite.lua" },
      { "nvim-telescope/telescope.nvim" },
    },
    event = "VeryLazy",
    config = function()
      require("bookmarks").setup({})
    end,
    keys = {
      -- Toggle bookmark on current line (prompts for name; empty name removes it)
      { "mm", "<cmd>BookmarksMark<cr>", desc = "Toggle bookmark" },

      -- Browse bookmarks in active list via Telescope
      { "mo", "<cmd>BookmarksGoto<cr>", desc = "Go to bookmark" },

      -- Browse all bookmark commands
      { "ma", "<cmd>BookmarksCommands<cr>", desc = "Bookmark commands" },

      -- Cycle bookmarks across files (replaces vim's next/prev mark jumps)
      { "]'", "<cmd>BookmarksGotoNextInList<cr>", desc = "Next bookmark" },
      { "['", "<cmd>BookmarksGotoPrevInList<cr>", desc = "Prev bookmark" },
    },
  },
}
