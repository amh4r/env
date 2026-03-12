-- Use biome when available (biome.json exists), fall back to prettier.
-- biome-check runs `biome check --fix` (format + lint fixes).
-- stop_after_first: use whichever formatter succeeds first.
return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        typescript = { "biome-check", "prettier", stop_after_first = true },
        typescriptreact = { "biome-check", "prettier", stop_after_first = true },
        javascript = { "biome-check", "prettier", stop_after_first = true },
        javascriptreact = { "biome-check", "prettier", stop_after_first = true },
        json = { "biome-check", "prettier", stop_after_first = true },
        jsonc = { "biome-check", "prettier", stop_after_first = true },
      },
    },
  },
}
