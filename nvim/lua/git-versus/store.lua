local M = {}

local git = require("git-versus.git")

--- Get the path to the store file for the current repo.
---@return string|nil
function M.store_path()
  local root = git.repo_root()
  if not root then
    return nil
  end
  local key = root:gsub("/", "%%")
  local dir = vim.fn.stdpath("data") .. "/git-versus"
  return dir .. "/" .. key .. ".json"
end

--- Load saved comparisons for the current repo.
---@return string[]
function M.load()
  local path = M.store_path()
  if not path then
    return {}
  end
  local f = io.open(path, "r")
  if not f then
    return {}
  end
  local content = f:read("*a")
  f:close()
  local ok, data = pcall(vim.json.decode, content)
  if not ok or type(data) ~= "table" then
    return {}
  end
  return data
end

--- Save comparisons for the current repo.
---@param comparisons string[]
function M.save(comparisons)
  local path = M.store_path()
  if not path then
    return
  end
  local dir = vim.fn.fnamemodify(path, ":h")
  vim.fn.mkdir(dir, "p")
  local f = io.open(path, "w")
  if not f then
    return
  end
  f:write(vim.json.encode(comparisons))
  f:close()
end

return M
