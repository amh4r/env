return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- Hide cursor position (line:col) from the right side
      opts.sections.lualine_z = {}

      -- Show the full relative file path instead of truncating to 3 segments
      opts.sections.lualine_c[4] = { LazyVim.lualine.pretty_path({ length = 0 }) }
    end,
  },
}
