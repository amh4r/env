return {
  "akinsho/bufferline.nvim",
  opts = {
    options = {
      numbers = "ordinal",
    },
  },
  keys = {
    -- <M-1> through <M-9> jump to the Nth visible tab
    { "<M-1>", function() require("bufferline").go_to(1, true) end, desc = "Go to buffer 1" },
    { "<M-2>", function() require("bufferline").go_to(2, true) end, desc = "Go to buffer 2" },
    { "<M-3>", function() require("bufferline").go_to(3, true) end, desc = "Go to buffer 3" },
    { "<M-4>", function() require("bufferline").go_to(4, true) end, desc = "Go to buffer 4" },
    { "<M-5>", function() require("bufferline").go_to(5, true) end, desc = "Go to buffer 5" },
    { "<M-6>", function() require("bufferline").go_to(6, true) end, desc = "Go to buffer 6" },
    { "<M-7>", function() require("bufferline").go_to(7, true) end, desc = "Go to buffer 7" },
    { "<M-8>", function() require("bufferline").go_to(8, true) end, desc = "Go to buffer 8" },
    { "<M-9>", function() require("bufferline").go_to(9, true) end, desc = "Go to buffer 9" },
  },
}
