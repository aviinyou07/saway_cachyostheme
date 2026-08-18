-- ==============================================================================
-- CYBER NOIR WORKSTATION // NEOVIM OPTIONS CONFIGURATION
-- ==============================================================================
-- Sets core editor defaults for ultra-low latency typing, clean screen real
-- estate, high-contrast diagnostics, and smooth buffer interactions.
-- ==============================================================================

local opt = vim.opt

-- ------------------------------------------------------------------------------
-- 1. LINE NUMBERS & VISUAL FRAMING
-- ------------------------------------------------------------------------------
opt.number = true               -- Display absolute line number on cursor row
opt.relativenumber = true       -- Display relative distance for jump operators (3j, 5k)
opt.signcolumn = "yes:2"        -- Always reserve two columns for git & LSP diagnostic icons
opt.cursorline = true           -- Highlight active cursor horizontal row
opt.termguicolors = true        -- Required for 24-bit RGB Cyber Noir design tokens

-- ------------------------------------------------------------------------------
-- 2. TAB VALUES & INDENTATION LOGIC
-- ------------------------------------------------------------------------------
opt.tabstop = 4                 -- Number of visual columns a Tab accounts for
opt.shiftwidth = 4              -- Spaces inserted for each indentation step (>> and <<)
opt.expandtab = true            -- Convert Tab keypresses directly into spaces
opt.smartindent = true          -- Auto-indent new lines based on syntax structure (C/Bash/Python)
opt.wrap = false                -- Never wrap code lines; keep clean visual horizon

-- ------------------------------------------------------------------------------
-- 3. SEARCH & REGEX EVALUATION
-- ------------------------------------------------------------------------------
opt.ignorecase = true           -- Ignore letter case when searching (case-insensitive)
opt.smartcase = true            -- Switch to case-sensitive when query includes uppercase letter
opt.incsearch = true            -- Jump to matching string instantly as you type
opt.hlsearch = false            -- Keep highlights clear after search query completes

-- ------------------------------------------------------------------------------
-- 4. BUFFER STORAGE & CLIPBOARD SYNC
-- ------------------------------------------------------------------------------
opt.clipboard = "unnamedplus"   -- Sync register directly with Wayland clipboard (wl-copy)
opt.undofile = true             -- Preserve undo revision timeline persistently across reboots
opt.swapfile = false            -- Disable swapfile clutter in version-controlled repositories
opt.backup = false              -- Avoid generating unwanted tildes or file duplicates
opt.updatetime = 200            -- Save swap / update diagnostics after 200ms idle delay
opt.timeoutlen = 300            -- Fast completion window for mapped key combinations

-- ------------------------------------------------------------------------------
-- 5. INTERACTIVE WINDOW SPLITING & VIEWPORT
-- ------------------------------------------------------------------------------
opt.splitright = true           -- Vertical window splits naturally spawn on the right
opt.splitbelow = true           -- Horizontal window splits spawn underneath active buffer
opt.scrolloff = 8               -- Maintain minimum 8 lines of top/bottom buffer horizon
opt.sidescrolloff = 8           -- Maintain horizontal spatial margin during side scrolling
opt.showmode = false            -- Omit redundancy; Lualine status bar displays active mode
opt.list = true                 -- Render invisible trailing characters for clean code review
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
