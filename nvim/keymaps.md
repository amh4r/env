# Find/Search

`<leader><space>` -- Find files
`<leader>ff` -- Find files
`<leader>sg` -- Grep. Can glob search (e.g. `myFunction -- -g *.ts`)
`<leader>sk` -- Search keymaps

Within snacks:
`<a-h>` -- Toggle hidden file visibility

# LSP

`gd` -- Definition
`gI` -- Go to implementation
`gD` -- Go to source definition
`gy` -- Go to type definition
`gr` -- Find references
`K` -- Hover documentation

## Diagnostics

`]d` -- Next
`[d` -- Previous
`]e` -- Next error
`[e` -- Previous error

## Code Actions

`<leader>cr` -- Rename (changes all occurrences)

# Marks (bookmarks.nvim)

`mm` -- Toggle
`mo` -- Picker
`]'` -- Next
`['` -- Previous

# File tree

`<leader>e` -- Toggle
`a` -- Create file in focused dir
`d` -- Delete file
`H` -- Toggle hidden file visibility

# Layout

## Buffers

`<S-h>` -- Move left
`<S-l>` -- Move right
`<leader>b6` -- Move to tab 6
`<leader>bd` -- Close
`<leader>bo` -- Close others
`<leader>bl` -- Close to the left
`<leader>br` -- Close to the right
`<leader>bP` -- Close non-pinned

`<leader>bp` -- Pin

## Tab pages

`gt` -- Next tab page
`<leader><tab><tab>` -- New
`<leader><tab>d` -- Close

## Windows

`<C-h>` -- Move left
`<C-l>` -- Move right
`<C-j>` -- Move down
`<C-k>` -- Move up

`<C-w>s` -- Horizontal split
`<C-w>v` -- Vertical split

`<C-w>q` -- Close current

# Git

## Gitsigns

`[h` -- Previous hunk
`]h` -- Next hunk
`<leader>ghp` -- Preview hunk (inline)
`<leader>ghr` -- Reset hunk
`<leader>ghb` -- Blame line
`<leader>ghB` -- Open blame gutter

## Diffview

`<leader>gv` -- Open diffview
`<leader>gV` -- Close diffview
`:DiffviewOpen main...HEAD` -- Open diffview and compare against the `main` branch

`]x` -- Next conflict
`[x` -- Prev conflict
`<leader>cO` -- Choose ours
`<leader>ct` -- Choose theirs

## Lazygit

`<leader>gs` -- Git status
`<leader>gg` -- Open lazygit

Inside lazygit:

`space` -- Stage file
`f` -- Fetch
`p` -- Pull
`P` -- Push
`A` -- Amend
`R` -- Reword commit message (while in commits panel)

# UI

`<leader>uh` -- Toggle inlay hints
`<leader>um` -- Toggle minimap

# Editing

`gc` -- Toggle comment (selection)
`gcc` -- Toggle comment (line)

# Vim Basics

`<C-o>` -- Jump back
`<C-i>` -- Jump forward
`M` -- Center of screen
`u` -- Undo
`<C-r>` -- Redo

`<C-b>` -- Up page
`<C-f>` -- Down page
`<C-u>` -- Up 1/2 page
`<C-d>` -- Down 1/2 page

`zb` -- Up (cursor to bottom)
`zz` -- Center cursor
`zt` -- Down (cursor to top)

# Resources

https://vim.rtorr.com
