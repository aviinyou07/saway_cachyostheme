-- ==============================================================================
-- CYBER NOIR WORKSTATION // NEOVIM AUTOCONFIG & EVENT HOOKS
-- ==============================================================================
-- Automated lifecycle hooks for visual highlighting, dynamic window resizing,
-- and restoration of cursor editing memory across restarts.
-- ==============================================================================

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local CyberGroup = augroup("CyberNoirWorkstation", { clear = true })

-- ------------------------------------------------------------------------------
-- 1. HIGHLIGHT ON YANK (Visual Feedback)
-- ------------------------------------------------------------------------------
-- Illuminates yanked code slices briefly with Accent Cyan / Green highlights
autocmd("TextYankPost", {
  group = CyberGroup,
  callback = function()
    vim.highlight.on_yank({
      higroup = "IncSearch",
      timeout = 250,
    })
  end,
})

-- ------------------------------------------------------------------------------
-- 2. DYNAMIC WINDOW RESIZING SYNC
-- ------------------------------------------------------------------------------
-- Automatically rebalances open split dimensions when resizing Kitty / Sway panes
autocmd("VimResized", {
  group = CyberGroup,
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})

-- ------------------------------------------------------------------------------
-- 3. EDITING POSITION MEMORY RESTORATION
-- ------------------------------------------------------------------------------
-- Restores cursor directly to its last known location when opening a file
autocmd("BufReadPost", {
  group = CyberGroup,
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      vim.cmd("normal! g`\"")
    end
  end,
})

-- ------------------------------------------------------------------------------
-- 4. AUTOMATIC TRAILING WHITESPACE STRIPPING ON SAVE
-- ------------------------------------------------------------------------------
autocmd("BufWritePre", {
  group = CyberGroup,
  pattern = "*",
  callback = function()
    local save_cursor = vim.fn.getpos(".")
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.setpos(".", save_cursor)
  end,
})
