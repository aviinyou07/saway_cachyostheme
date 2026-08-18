-- ==============================================================================
-- CYBER NOIR WORKSTATION // NEOVIM EDITOR & SYNTAX SEARCH SUITE
-- ==============================================================================
-- Configures Telescope fuzzy searching with Cyan border frames and full
-- Nvim-Treesitter language syntax highlighting & AST structural comprehension.
-- ==============================================================================

return {
  -- ---------------------------------------------------------------------------
  -- 1. TELESCOPE // High-Speed Fuzzy Search Architecture
  -- ---------------------------------------------------------------------------
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")

      telescope.setup({
        defaults = {
          prompt_prefix = "   ",
          selection_caret = " ❯ ",
          path_display = { "truncate" },
          sorting_strategy = "ascending",
          layout_config = {
            horizontal = {
              prompt_position = "top",
              preview_width = 0.55,
              results_width = 0.8,
            },
            vertical = {
              mirror = false,
            },
            width = 0.87,
            height = 0.80,
            preview_cutoff = 120,
          },
          file_ignore_patterns = { "node_modules", ".git/", "dist/", "build/" },
          mappings = {
            i = {
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-j>"] = actions.move_selection_next,
              ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
              ["<C-c>"] = actions.close,
            },
            n = {
              ["q"] = actions.close,
              ["<C-c>"] = actions.close,
            },
          },
        },
        pickers = {
          find_files = {
            hidden = true,
            theme = "dropdown",
          },
          buffers = {
            show_all_buffers = true,
            sort_lastused = true,
            theme = "dropdown",
            mappings = {
              i = { ["<C-d>"] = actions.delete_buffer },
            },
          },
        },
      })
    end,
  },

  -- ---------------------------------------------------------------------------
  -- 2. NVIM-TREESITTER // AST Parser & Code Syntax Illumination
  -- ---------------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        -- Senior Linux engineer and DevOps core syntax grammar inventory
        ensure_installed = {
          "bash",
          "c",
          "cpp",
          "css",
          "dockerfile",
          "go",
          "html",
          "javascript",
          "json",
          "lua",
          "luadoc",
          "markdown",
          "markdown_inline",
          "python",
          "regex",
          "rust",
          "sql",
          "toml",
          "typescript",
          "vim",
          "vimdoc",
          "yaml",
          "zig",
        },
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,
        },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<C-space>",
            node_incremental = "<C-space>",
            scope_incremental = "<C-s>",
            node_decremental = "<M-space>",
          },
        },
      })
    end,
  },
}
