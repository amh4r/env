return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      -- Without this, gutter signs go stale after commits until the buffer is reopened.
      watch_gitdir = {
        enable = true,
        follow_files = true,
      },
      -- Reduce scroll lag by debouncing gitsigns updates
      update_debounce = 500,
    },
    event = "VeryLazy",
  },
}
