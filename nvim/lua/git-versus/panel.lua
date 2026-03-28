local NuiTree = require("nui.tree")
local NuiLine = require("nui.line")
local NuiSplit = require("nui.split")
local NuiInput = require("nui.input")
local event = require("nui.utils.autocmd").event

local git = require("git-versus.git")
local store = require("git-versus.store")

local M = {}

---@type NuiSplit|nil
local split = nil
---@type string[]
local comparisons = {}
---@type NuiTree|nil
local tree = nil
---@type table<string, boolean>
local expanded = {}

local devicons_ok, devicons = pcall(require, "nvim-web-devicons")

local status_hl = {
  M = "GitSignsChange",
  A = "GitSignsAdd",
  D = "GitSignsDelete",
  R = "GitSignsChange",
  C = "GitSignsChange",
  ["?"] = "Comment",
}

local function get_file_icon(filename)
  if not devicons_ok then
    return "", nil
  end
  local ext = vim.fn.fnamemodify(filename, ":e")
  local icon, hl = devicons.get_icon(filename, ext, { default = true })
  return icon or "", hl
end

local function has_working_tree(comparison)
  local _, right = git.parse_comparison(comparison)
  return right == "WorkingTree"
end

local function build_tree_nodes()
  local nodes = {}
  for _, comp in ipairs(comparisons) do
    local children = {}
    if expanded[comp] then
      local left, right = git.parse_comparison(comp)
      if left and right then
        local files = git.changed_files(left, right)
        for i, file in ipairs(files) do
          local child = NuiTree.Node({
            text = file.name,
            status = file.status,
            type = "file",
            comparison = comp,
            is_last = i == #files,
          })
          table.insert(children, child)
        end
        if #files == 0 then
          local child = NuiTree.Node({ text = "(no changes)", type = "empty", is_last = true })
          table.insert(children, child)
        end
      end
    end
    local node = NuiTree.Node({ text = comp, type = "comparison" }, children)
    if expanded[comp] then
      node:expand()
    end
    table.insert(nodes, node)
  end
  return nodes
end

local function render_tree()
  if not split or not tree then
    return
  end
  tree:set_nodes(build_tree_nodes())
  tree:render()
end

local function refresh_working_tree_comparisons()
  if not split then
    return
  end
  local needs_refresh = false
  for _, comp in ipairs(comparisons) do
    if expanded[comp] and has_working_tree(comp) then
      needs_refresh = true
      break
    end
  end
  if needs_refresh then
    render_tree()
  end
end

--- Open a scratch buffer with the contents of a file at a given ref.
local function open_ref_buffer(ref, file)
  local content = vim.fn.systemlist({ "git", "show", ref .. ":" .. file })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  vim.api.nvim_set_option_value("buflisted", false, { buf = buf })
  vim.api.nvim_buf_set_name(buf, "git-versus://" .. ref .. ":" .. file)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  local ft = vim.filetype.match({ filename = file })
  if ft then
    vim.api.nvim_set_option_value("filetype", ft, { buf = buf })
  end
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  return buf
end

local function open_diff(node)
  if node.type ~= "file" then
    return
  end
  local comp = node.comparison
  local left, right = git.parse_comparison(comp)
  if not left or not right then
    return
  end

  -- Focus the window to the left of the panel
  local panel_win = vim.api.nvim_get_current_win()
  vim.cmd("wincmd h")
  if vim.api.nvim_get_current_win() == panel_win then
    vim.cmd("leftabove vsplit")
  end

  -- Remember the main window and its original buffer so we can restore on close
  local main_win = vim.api.nvim_get_current_win()
  local original_buf = vim.api.nvim_win_get_buf(main_win)

  -- If the file doesn't exist on the left ref, just open it directly (new file)
  if not git.file_exists_at_ref(left, node.text) then
    if right == "WorkingTree" then
      vim.cmd("edit " .. node.text)
    else
      local buf = open_ref_buffer(right, node.text)
      if buf then
        vim.api.nvim_win_set_buf(0, buf)
      end
    end
    return
  end

  -- Open the left ref in a scratch buffer
  local left_buf = open_ref_buffer(left, node.text)
  if not left_buf then
    vim.notify("Could not read " .. left .. ":" .. node.text, vim.log.levels.ERROR)
    return
  end

  -- Right side: working tree file or ref buffer
  if right == "WorkingTree" then
    vim.cmd("edit " .. node.text)
    vim.cmd("diffthis")
    vim.w.git_versus_diff = true
    vim.w.git_versus_restore_buf = original_buf
    vim.cmd("leftabove vsplit")
    vim.api.nvim_win_set_buf(0, left_buf)
    vim.cmd("diffthis")
    vim.w.git_versus_diff = true
  else
    local right_buf = open_ref_buffer(right, node.text)
    if not right_buf then
      vim.notify("Could not read " .. right .. ":" .. node.text, vim.log.levels.ERROR)
      vim.api.nvim_buf_delete(left_buf, { force = true })
      return
    end
    vim.api.nvim_win_set_buf(0, right_buf)
    vim.cmd("diffthis")
    vim.w.git_versus_diff = true
    vim.w.git_versus_restore_buf = original_buf
    vim.cmd("leftabove vsplit")
    vim.api.nvim_win_set_buf(0, left_buf)
    vim.cmd("diffthis")
    vim.w.git_versus_diff = true
  end
end

local function add_comparison()
  local input = NuiInput({
    position = "50%",
    size = { width = 50 },
    border = {
      style = "rounded",
      text = { top = " Add comparison ", top_align = "center" },
    },
  }, {
    prompt = " ",
    on_submit = function(value)
      if not value or value == "" then
        return
      end
      local ok, err = git.validate_comparison(value)
      if not ok then
        vim.notify(err, vim.log.levels.ERROR, { title = "git-versus" })
        -- Reopen input with error displayed
        vim.schedule(function()
          local retry = NuiInput({
            position = "50%",
            size = { width = 50 },
            border = {
              style = "rounded",
              text = {
                top = " Add comparison ",
                top_align = "center",
                bottom = " " .. err .. " ",
                bottom_align = "center",
              },
            },
          }, {
            prompt = " ",
            default_value = value,
            on_submit = function(retry_value)
              if not retry_value or retry_value == "" then
                return
              end
              local rok, rerr = git.validate_comparison(retry_value)
              if not rok then
                vim.notify(rerr, vim.log.levels.ERROR, { title = "git-versus" })
                return
              end
              table.insert(comparisons, retry_value)
              store.save(comparisons)
              render_tree()
            end,
          })
          retry:mount()
          retry:on(event.BufLeave, function()
            retry:unmount()
          end)
        end)
        return
      end
      table.insert(comparisons, value)
      store.save(comparisons)
      render_tree()
    end,
  })
  input:mount()
  input:on(event.BufLeave, function()
    input:unmount()
  end)
end

local function delete_comparison()
  if not tree then
    return
  end
  local node = tree:get_node()
  if not node or node.type ~= "comparison" then
    return
  end
  for i, comp in ipairs(comparisons) do
    if comp == node.text then
      table.remove(comparisons, i)
      expanded[comp] = nil
      break
    end
  end
  store.save(comparisons)
  render_tree()
end

local function collapse_node()
  if not tree then
    return
  end
  local node = tree:get_node()
  if not node then
    return
  end
  if node.type == "comparison" and expanded[node.text] then
    expanded[node.text] = nil
    node:collapse()
    render_tree()
  elseif node.type == "file" or node.type == "empty" then
    -- Collapse parent comparison and move cursor to it
    local parent_comp = node.comparison
    if parent_comp and expanded[parent_comp] then
      expanded[parent_comp] = nil
      render_tree()
      -- Move cursor to the parent comparison line
      for i, comp in ipairs(comparisons) do
        if comp == parent_comp then
          vim.api.nvim_win_set_cursor(0, { i, 0 })
          break
        end
      end
    end
  end
end

local function toggle_node()
  if not tree then
    return
  end
  local node = tree:get_node()
  if not node then
    return
  end
  if node.type == "comparison" then
    if expanded[node.text] then
      expanded[node.text] = nil
      node:collapse()
    else
      expanded[node.text] = true
      node:expand()
    end
    render_tree()
  elseif node.type == "file" then
    open_diff(node)
  end
end

local augroup = vim.api.nvim_create_augroup("GitVersus", { clear = true })

function M.open()
  if split then
    return
  end

  comparisons = store.load()

  split = NuiSplit({
    relative = "editor",
    position = "right",
    size = 40,
    buf_options = {
      buftype = "nofile",
      modifiable = false,
      swapfile = false,
      filetype = "git-versus",
      buflisted = false,
    },
    win_options = {
      number = false,
      relativenumber = false,
      cursorline = true,
      signcolumn = "no",
      winfixwidth = true,
      winbar = "%=Git Versus%=",
    },
  })
  split:mount()

  -- Set cursorline with a visible highlight (matching snacks explorer style)
  vim.api.nvim_set_option_value("cursorline", true, { win = split.winid })
  vim.api.nvim_set_option_value("winhighlight", "CursorLine:Visual", { win = split.winid })

  tree = NuiTree({
    bufnr = split.bufnr,
    nodes = build_tree_nodes(),
    prepare_node = function(node)
      local line = NuiLine()
      if node.type == "comparison" then
        local icon = expanded[node.text] and "▼ " or "▶ "
        line:append(icon, "Special")
        line:append(node.text, "Title")
      elseif node.type == "file" then
        local guide = node.is_last and "└─ " or "├─ "
        line:append(guide, "Comment")
        local status = node.status or "M"
        local display_status = status == "?" and "??" or status
        line:append(display_status .. " ", status_hl[status] or "Normal")
        local icon, icon_hl = get_file_icon(node.text)
        line:append(icon .. " ", icon_hl)
        line:append(node.text)
      elseif node.type == "empty" then
        local guide = node.is_last and "└─ " or "├─ "
        line:append(guide, "Comment")
        line:append(node.text, "Comment")
      end
      return line
    end,
  })
  tree:render()

  -- Keymaps
  local buf = split.bufnr
  local opts = { noremap = true, nowait = true }

  vim.api.nvim_buf_set_keymap(buf, "n", "a", "", vim.tbl_extend("force", opts, {
    callback = add_comparison,
  }))
  vim.api.nvim_buf_set_keymap(buf, "n", "d", "", vim.tbl_extend("force", opts, {
    callback = delete_comparison,
  }))
  vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", "", vim.tbl_extend("force", opts, {
    callback = toggle_node,
  }))
  vim.api.nvim_buf_set_keymap(buf, "n", "l", "", vim.tbl_extend("force", opts, {
    callback = toggle_node,
  }))
  vim.api.nvim_buf_set_keymap(buf, "n", "h", "", vim.tbl_extend("force", opts, {
    callback = collapse_node,
  }))
  vim.api.nvim_buf_set_keymap(buf, "n", "Z", "", vim.tbl_extend("force", opts, {
    callback = function()
      expanded = {}
      render_tree()
    end,
  }))
  vim.api.nvim_buf_set_keymap(buf, "n", "q", "", vim.tbl_extend("force", opts, {
    callback = function()
      M.close()
    end,
  }))

  -- Auto-refresh WorkingTree comparisons on save
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = augroup,
    callback = refresh_working_tree_comparisons,
  })

  -- Clean up on window close
  split:on(event.WinClosed, function()
    M.close()
  end)
end

function M.close()
  vim.api.nvim_clear_autocmds({ group = augroup })
  if split then
    split:unmount()
    split = nil
    tree = nil
  end
end

function M.toggle()
  if split then
    M.close()
  else
    M.open()
  end
end

return M
