-- ==============================================================================
-- CYBER STUDIO // CATPPUCCIN MOCHA REMAPPED ONTO THE DESIGN TOKENS
-- ==============================================================================
-- Every colour below comes from ../../../PALETTE.md. Catppuccin is used only as
-- a highlight-group scaffold; its palette is fully overridden so the editor
-- agrees with kitty's ANSI mapping and with the desktop chrome.
-- ==============================================================================

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha", -- Default mocha profile enhanced with Cyber Noir overrides
        transparent_background = true, -- Mandatory glassmorphic transparency
        show_end_of_buffer = false,
        term_colors = true,
        dim_inactive = {
          enabled = true,
          shade = "dark",
          percentage = 0.20,
        },
        no_italic = false,
        no_bold = false,
        styles = {
          comments = { "italic" },
          conditionals = { "italic" },
          loops = {},
          functions = { "bold" },
          keywords = {},
          strings = {},
          variables = {},
          numbers = {},
          booleans = { "bold", "italic" },
          properties = {},
          types = { "bold" },
          operators = {},
        },
        color_overrides = {
          mocha = {
            -- Canvas (see PALETTE.md)
            base      = "#090C14", -- bg
            mantle    = "#0F172A", -- surface
            crust     = "#060911", -- deeper than bg, for shadowed edges
            surface0  = "#111827", -- card
            surface1  = "#1E293B", -- border
            surface2  = "#334155",

            -- Accents
            blue      = "#38BDF8", -- accent
            sapphire  = "#38BDF8",
            sky       = "#7DD3FC",
            green     = "#22C55E", -- ok
            teal      = "#2DD4BF", -- info
            mauve     = "#A78BFA", -- alt
            lavender  = "#C4B5FD",
            yellow    = "#FBBF24", -- warn
            peach     = "#FB923C",
            red       = "#EF4444", -- err
            maroon    = "#F87171",

            -- Typography
            text      = "#F8FAFC", -- text
            subtext1  = "#CBD5E1", -- text-2
            subtext0  = "#94A3B8",
            overlay2  = "#64748B", -- text-3
            overlay1  = "#556074",
            overlay0  = "#475569", -- text-4
          },
        },
        custom_highlights = function(colors)
          return {
            -- Floating windows and borders framed in accent
            NormalFloat = { bg = colors.surface0 },
            FloatBorder = { fg = colors.blue, bg = "NONE" },
            
            -- Telescope Fuzzy Finder visual geometry
            TelescopeBorder       = { fg = colors.blue, bg = "NONE" },
            TelescopePromptBorder = { fg = colors.green, bg = colors.surface0 },
            TelescopePromptNormal = { bg = colors.surface0 },
            TelescopeResultsNormal= { bg = "NONE" },
            TelescopePreviewNormal= { bg = "NONE" },

            -- Cursorline & Visual Selection overrides
            CursorLine      = { bg = "#0F172A" },
            Visual          = { bg = "#1E293B", fg = colors.text },

            -- Diagnostic Sign Highlights
            DiagnosticError = { fg = colors.red, bold = true },
            DiagnosticWarn  = { fg = colors.yellow, bold = true },
            DiagnosticInfo  = { fg = colors.blue, bold = true },
            DiagnosticHint  = { fg = colors.green, bold = true },
            
            -- Line Number contrast
            LineNr       = { fg = colors.overlay0 },
            CursorLineNr = { fg = colors.blue, bold = true },
          }
        end,
        integrations = {
          cmp = true,
          gitsigns = true,
          nvimtree = true,
          treesitter = true,
          notify = true,
          telescope = {
            enabled = true,
          },
          markdown = true,
          mason = true,
          native_lsp = {
            enabled = true,
            virtual_text = {
              errors = { "italic" },
              hints = { "italic" },
              warnings = { "italic" },
              information = { "italic" },
            },
            underlines = {
              errors = { "underline" },
              hints = { "underline" },
              warnings = { "underline" },
              information = { "underline" },
            },
          },
        },
      })

      -- Activate theme immediately upon startup
      vim.cmd.colorscheme("catppuccin")
    end,
  },
}
