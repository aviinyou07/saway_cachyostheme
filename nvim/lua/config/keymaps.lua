-- ==============================================================================
-- CYBER NOIR WORKSTATION // NEOVIM SENIOR ENGINEERING KEYMAPS
-- ==============================================================================
-- Ergonomic keyboard shortcuts optimized for muscle memory, rapid pane jumps,
-- split manipulation, and frictionless buffer management.
-- ==============================================================================

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- ------------------------------------------------------------------------------
-- 1. GENERAL CONVENience & NORMAL MODE RESETS
-- ------------------------------------------------------------------------------
-- Rapid exit from Insert mode using double "jk" or "kj"
map("i", "jk", "<ESC>", { desc = "Exit Insert Mode immediately" })
map("i", "kj", "<ESC>", { desc = "Exit Insert Mode immediately" })

-- Fast file persistence across Normal, Insert, and Visual modes
map({ "n", "i", "v" }, "<C-s>", "<ESC>:w<CR>", { desc = "Save active buffer immediately", silent = true })

-- Clear leftover highlight patterns and diagnostic popups
map("n", "<leader>q", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights", silent = true })

-- ------------------------------------------------------------------------------
-- 2. WINDOW SPLITING & SPATIAL PANING
-- ------------------------------------------------------------------------------
-- Create horizontal and vertical splits
map("n", "<leader>sv", "<cmd>vsplit<CR>", { desc = "Split window vertically right" })
map("n", "<leader>sh", "<cmd>split<CR>",  { desc = "Split window horizontally below" })
map("n", "<leader>se", "<C-w>=",         { desc = "Equalize split spatial widths and heights" })
map("n", "<leader>sx", "<cmd>close<CR>",  { desc = "Close currently active window pane" })

-- Direct window jumping without repetitive <C-w> prefixes
map("n", "<C-h>", "<C-w>h", { desc = "Move focus to left window pane" })
map("n", "<C-j>", "<C-w>j", { desc = "Move focus to bottom window pane" })
map("n", "<C-k>", "<C-w>k", { desc = "Move focus to top window pane" })
map("n", "<C-l>", "<C-w>l", { desc = "Move focus to right window pane" })

-- ------------------------------------------------------------------------------
-- 3. BUFFER NAVIGATION & CYCLE OPERATORS
-- ------------------------------------------------------------------------------
-- Fast horizontal sliding between active open file buffers
map("n", "<S-l>", "<cmd>bnext<CR>",     { desc = "Navigate to next open buffer tab" })
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Navigate to previous open buffer tab" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete active buffer without closing splits" })

-- ------------------------------------------------------------------------------
-- 4. CODE BLOCK INDENTATION & LINE DISPLACEMENT
-- ------------------------------------------------------------------------------
-- Maintain active Visual mode selection block when indenting/outdenting
map("v", "<", "<gv", { desc = "Outdent visual line block and reselect" })
map("v", ">", ">gv", { desc = "Indent visual line block and reselect" })

-- Move highlighted visual blocks up or down across neighboring code lines
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Shift selected visual block downwards" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Shift selected visual block upwards" })

-- ------------------------------------------------------------------------------
-- 5. FILE EXPLORER & TERMINAL LAUNCHERS (Mapped to Plugins)
-- ------------------------------------------------------------------------------
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle NvimTree sidebar explorer" })
map("n", "<C-\\>", "<cmd>ToggleTerm direction=float<CR>", { desc = "Drop floating Cyber Noir terminal" })

-- Telescope Fuzzy Search suite shortcuts
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "Fuzzy search files across workspace" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>",  { desc = "Live regex search across workspace" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>",    { desc = "Search open editor buffers" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>",  { desc = "Search Neovim internal help manual" })
