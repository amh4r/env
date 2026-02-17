return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- Hide cursor position (line:col) from the right side
      opts.sections.lualine_z = {}
    end,
  },
}
