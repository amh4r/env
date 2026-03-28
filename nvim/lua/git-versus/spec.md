# Problem

Neovim doesn't have a plugin that replicates GitLens' "Search & Compare" feature.

# Plugin

**Name:** git-versus.nvim

**Dependencies:** nui.nvim, diffview.nvim

**Location:** `nvim/lua/git-versus/` (module), `nvim/lua/plugins/git-versus.lua` (plugin spec)

# Implementation

## Side panel

A dedicated panel on the right side of the editor. Shows a tree of git ref comparisons.

- Root nodes are git ref comparisons (e.g. `main...my-feature`)
- Expanding a root node lists the files changed between the two refs
- Files show git status (`M`, `A`, `D`, `??`) and file type icons

```
▶ main...WorkingTree
▼ stacked-pr-1...stacked-pr-2
  file-1.ts
  file-2.ts
▶ 3a1a670...HEAD
```

The tree should feel like the lazyvim file explorer (neo-tree), since nui.nvim is the same foundation.

## WorkingTree

`WorkingTree` is a special ref representing the current state of the working tree, including uncommitted changes and untracked files. When a comparison includes `WorkingTree`, the side panel file list auto-refreshes on `BufWritePost`. Untracked files are opened directly (no diff) since they have no counterpart in the compared ref.

## Keybindings

### Global

- `<leader>gc` -- Toggle the git-versus panel.
- `<leader>gq` -- Close the active diff and restore the previous buffer.

### Panel

- `a` -- Add a comparison. Opens a nui text input where the user types a comparison string (e.g. `main...my-feature`). Both refs are validated before adding; if either ref is invalid, show an error in the input overlay.
- `d` -- Delete the comparison under the cursor.
- `Return` -- On a comparison node, expand/collapse. On a file node, open an inline side-by-side diff using Neovim's built-in diff mode.
- `Z` -- Collapse all expanded comparisons.
- `q` -- Close the panel.

## Persistence

Comparisons are persisted per project (per git repo root) in `stdpath("data")`, keyed by repo root path. Restored when the panel is reopened.

# Out of scope

- Insertion/deletion counts per file
- Tab in the file explorer panel (instead of standalone right panel)
- Filesystem watching via `vim.uv` (using `BufWritePost` for now)

# Context

GitLens is a VS Code extension. Its "Search & Compare" feature looks like this:
