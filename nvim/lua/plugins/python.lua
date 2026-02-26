-- Run ruff's organize imports code action on save.
return {
  "stevearc/conform.nvim",
  opts = function(_, opts)
    opts.formatters_by_ft = opts.formatters_by_ft or {}
    opts.formatters_by_ft.python = opts.formatters_by_ft.python or {}

    opts.formatters = opts.formatters or {}
    opts.formatters.ruff_organize_imports = {
      command = "ruff",
      args = { "check", "--select", "I", "--fix", "-" },
      stdin = true,
    }

    opts.formatters_by_ft.python = { "ruff_organize_imports", lsp_format = "last" }
  end,
}
