-- ==============================================================================
-- CYBER STUDIO WORKSTATION // NEOVIM MASTER INIT.LUA
-- ==============================================================================
-- Engineered for CachyOS Linux DevOps and Software Engineering.
-- Modular architecture powered by lazy.nvim plugin manager.
--
-- Core capabilities: Catppuccin Mocha remapped onto the Cyber Studio tokens
-- full transparent backgrounds, LSP/Treesitter, floating terminal, and Git toolbelt.
-- ==============================================================================

-- Enforce Space as primary leader key across all keybindings & operator mappings
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load foundational core configuration modules
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- ------------------------------------------------------------------------------
-- LAZY.NVIM PLUGIN MANAGER BOOTSTRAPPER
-- ------------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim plugin architecture:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to cancel IDE bootstrap...", "MoreMsg" },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Initialize Lazy architecture pointing directly to modular lua/plugins/ folder
require("lazy").setup({
  import = "plugins",
}, {
  ui = {
    border = "rounded",
    icons = {
      cmd = "⌘",
      config = "🛠",
      event = "📅",
      ft = "📂",
      init = "⚙",
      keys = "🗝",
      plugin = "🔌",
      runtime = "💻",
      require = "🌙",
      source = "📄",
      start = "🚀",
      task = "📌",
      lazy = "💤 ",
    },
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
