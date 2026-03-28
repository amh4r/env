local M = {}

--- Get the root of the current git repo.
---@return string|nil
function M.repo_root()
  local out = vim.fn.systemlist("git rev-parse --show-toplevel")
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return out[1]
end

--- Validate that a git ref exists.
---@param ref string
---@return boolean
function M.ref_exists(ref)
  vim.fn.system({ "git", "rev-parse", "--verify", ref })
  return vim.v.shell_error == 0
end

--- Parse a comparison string like "main...feature" into two refs.
---@param comparison string
---@return string|nil, string|nil
function M.parse_comparison(comparison)
  local left, right = comparison:match("^(.+)%.%.%.(.+)$")
  return left, right
end

--- Validate a comparison string. Returns true or (false, error message).
---@param comparison string
---@return boolean, string|nil
function M.validate_comparison(comparison)
  local left, right = M.parse_comparison(comparison)
  if not left or not right then
    return false, "Invalid format. Use: ref1...ref2"
  end
  if right ~= "WorkingTree" and not M.ref_exists(right) then
    return false, "Invalid ref: " .. right
  end
  if not M.ref_exists(left) then
    return false, "Invalid ref: " .. left
  end
  return true, nil
end

--- Get list of files changed between two refs, with status.
---@param left string
---@param right string
---@return table[] -- { name: string, status: string }
function M.changed_files(left, right)
  local cmd
  if right == "WorkingTree" then
    cmd = { "git", "diff", "--name-status", left }
  else
    cmd = { "git", "diff", "--name-status", left .. "..." .. right }
  end
  local out = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    return {}
  end

  local files = {}
  for _, line in ipairs(out) do
    local status, name = line:match("^(%S+)%s+(.+)$")
    if status and name then
      table.insert(files, { name = name, status = status })
    end
  end

  -- Include untracked files for WorkingTree comparisons
  if right == "WorkingTree" then
    local untracked = vim.fn.systemlist({ "git", "ls-files", "--others", "--exclude-standard" })
    if vim.v.shell_error == 0 then
      local seen = {}
      for _, f in ipairs(files) do
        seen[f.name] = true
      end
      for _, f in ipairs(untracked) do
        if not seen[f] then
          table.insert(files, { name = f, status = "?" })
        end
      end
    end
  end

  return files
end

--- Check if a file is untracked.
---@param file string
---@return boolean
function M.is_untracked(file)
  vim.fn.system({ "git", "ls-files", "--error-unmatch", file })
  return vim.v.shell_error ~= 0
end

--- Check if a file exists at a given ref.
---@param ref string
---@param file string
---@return boolean
function M.file_exists_at_ref(ref, file)
  vim.fn.system({ "git", "cat-file", "-e", ref .. ":" .. file })
  return vim.v.shell_error == 0
end

return M
