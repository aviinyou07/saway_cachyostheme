-- ==============================================================================
-- CYBER STUDIO WORKSTATION // NEOVIM USER INTERFACE & DEVOPS SUITE
-- ==============================================================================
-- Implements custom Cyber Noir Lualine status bar, NvimTree file navigator,
-- ToggleTerm terminal execution dock, and Gitsigns delta indicators.
-- ==============================================================================

return {
  -- ---------------------------------------------------------------------------
  -- 1. LUALINE STATUSBAR // Custom Cyber Noir Mode Highlighting
  -- ---------------------------------------------------------------------------
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    config = function()
      -- Define dynamic Cyber Noir palette mapping for Lualine modes
      -- Mode colours come from ../../../PALETTE.md. Sections b/c use card and
      -- surface so the statusline sits on the same ramp as the rest of the UI.
      local cyber_palette = {
        normal = {
          a = { bg = "#38BDF8", fg = "#090C14", gui = "bold" }, -- accent
          b = { bg = "#111827", fg = "#CBD5E1" },
          c = { bg = "#0F172A", fg = "#64748B" },
        },
        insert = {
          a = { bg = "#22C55E", fg = "#090C14", gui = "bold" }, -- ok
          b = { bg = "#111827", fg = "#CBD5E1" },
          c = { bg = "#0F172A", fg = "#64748B" },
        },
        visual = {
          a = { bg = "#A78BFA", fg = "#090C14", gui = "bold" }, -- alt
          b = { bg = "#111827", fg = "#CBD5E1" },
          c = { bg = "#0F172A", fg = "#64748B" },
        },
        replace = {
          a = { bg = "#EF4444", fg = "#F8FAFC", gui = "bold" }, -- err
          b = { bg = "#111827", fg = "#CBD5E1" },
          c = { bg = "#0F172A", fg = "#64748B" },
        },
        command = {
          a = { bg = "#FBBF24", fg = "#090C14", gui = "bold" }, -- warn
          b = { bg = "#111827", fg = "#CBD5E1" },
          c = { bg = "#0F172A", fg = "#64748B" },
        },
        inactive = {
          a = { bg = "#0F172A", fg = "#64748B" },
          b = { bg = "#0F172A", fg = "#64748B" },
          c = { bg = "#0F172A", fg = "#475569" },
        },
      }

      require("lualine").setup({
        options = {
          theme = cyber_palette,
          component_separators = { left = "│", right = "│" },
          section_separators = { left = "", right = "" },
          disabled_filetypes = { "NvimTree", "ToggleTerm", "alpha" },
          always_divide_middle = true,
          globalstatus = true,
        },
        sections = {
          lualine_a = { { "mode", icon = "" } },
          lualine_b = {
            { "branch", icon = "", color = { fg = "#22C55E", gui = "bold" } },
            {
              "diff",
              symbols = { added = " ", modified = " ", removed = " " },
              diff_color = {
                added = { fg = "#22C55E" },
                modified = { fg = "#38BDF8" },
                removed = { fg = "#EF4444" },
              },
            },
          },
          lualine_c = { { "filename", path = 1, file_status = true, symbols = { modified = " 󰌾", readonly = " " } } },
          lualine_x = {
            {
              "diagnostics",
              sources = { "nvim_lsp" },
              symbols = { error = " ", warn = " ", info = " ", hint = " " },
              diagnostics_color = {
                error = { fg = "#EF4444" },
                warn = { fg = "#FBBF24" },
                info = { fg = "#38BDF8" },
                hint = { fg = "#22C55E" },
              },
            },
            { "encoding" },
            { "fileformat", icons_enabled = true },
            { "filetype", colored = true },
          },
          lualine_y = { { "progress", color = { fg = "#38BDF8", gui = "bold" } } },
          lualine_z = { { "location", icon = "", color = { fg = "#090C14", bg = "#38BDF8", gui = "bold" } } },
        },
      })
    end,
  },

  -- ---------------------------------------------------------------------------
  -- 2. NVIM-TREE // Minimalist File System Explorer
  -- ---------------------------------------------------------------------------
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        disable_netrw = true,
        hijack_netrw = true,
        view = {
          width = 34,
          relativenumber = true,
          signcolumn = "yes",
        },
        renderer = {
          indent_markers = {
            enable = true,
            icons = { corner = "└", edge = "│", item = "├", none = " " },
          },
          icons = {
            show = { file = true, folder = true, folder_arrow = true, git = true },
            glyphs = {
              folder = { arrow_closed = "", arrow_open = "", default = "", open = "" },
              git = { unstaged = "✗", staged = "✓", unmerged = "", renamed = "➜", untracked = "★", deleted = "", ignored = "◌" },
            },
          },
          special_files = { "Cargo.toml", "Makefile", "README.md", "package.json", "docker-compose.yml" },
        },
        git = { enable = true, ignore = false, timeout = 500 },
        actions = {
          open_file = { quit_on_open = false, window_picker = { enable = true } },
        },
      })
    end,
  },

  -- ---------------------------------------------------------------------------
  -- 3. TOGGLETERM // DevOps Floating Terminal Controller
  -- ---------------------------------------------------------------------------
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        size = 20,
        open_mapping = [[<c-\>]],
        hide_numbers = true,
        shade_terminals = false,
        shading_factor = "2",
        start_in_insert = true,
        persist_size = true,
        direction = "float",
        close_on_exit = true,
        shell = vim.o.shell,
        float_opts = {
          border = "rounded",
          winblend = 10,
          title_pos = "center",
        },
        highlights = {
          FloatBorder = { guifg = "#38BDF8", guibg = "NONE" },
          NormalFloat = { guibg = "#111827" },
        },
      })
    end,
  },

  -- ---------------------------------------------------------------------------
  -- 4. GITSIGNS // Real-time Margin Diff Markers
  -- ---------------------------------------------------------------------------
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("gitsigns").setup({
        signs = {
          add          = { text = "│" },
          change       = { text = "│" },
          delete       = { text = "_" },
          topdelete    = { text = "‾" },
          changedelete = { text = "~" },
          untracked    = { text = "┆" },
        },
        signs_staged = {
          add          = { text = "│" },
          change       = { text = "│" },
          delete       = { text = "_" },
          topdelete    = { text = "‾" },
          changedelete = { text = "~" },
        },
        current_line_blame = true,
        current_line_blame_opts = {
          virt_text = true,
          virt_text_pos = "eol",
          delay = 400,
        },
        current_line_blame_formatter = "    <author>, <author_time:%R> • <summary>",
      })
      
      -- Force exact Cyber Noir coloring on margin delta columns
      vim.api.nvim_set_hl(0, "GitSignsAdd",    { fg = "#22C55E", bg = "NONE" })
      vim.api.nvim_set_hl(0, "GitSignsChange", { fg = "#38BDF8", bg = "NONE" })
      vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = "#EF4444", bg = "NONE" })
    end,
  },
}
