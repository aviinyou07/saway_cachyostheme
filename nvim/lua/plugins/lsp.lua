-- ==============================================================================
-- CYBER NOIR WORKSTATION // LSP, AUTOCOMPLETION & DIAGNOSTICS SUITE
-- ==============================================================================
-- Integrates Mason package manager, LSPConfig language servers for DevOps, and
-- ultra-responsive nvim-cmp completion popups styled with cyan/green icons.
-- ==============================================================================

return {
  -- ---------------------------------------------------------------------------
  -- 1. MASON // Automated LSP & Linter Executable Manager
  -- ---------------------------------------------------------------------------
  {
    "williamboman/mason.nvim",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "neovim/nvim-lspconfig",
    },
    config = function()
      -- Bootstrap Mason UI styled in Cyber Noir aesthetic
      require("mason").setup({
        ui = {
          border = "rounded",
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      })

      -- Target language servers for essential Linux systems & DevOps languages
      require("mason-lspconfig").setup({
        ensure_installed = {
          "bashls",       -- Bash / Shell scripts
          "pyright",      -- Python architecture & diagnostics
          "ts_ls",        -- TypeScript / JavaScript engine
          "jsonls",       -- JSON / JSONC validator
          "yamlls",       -- YAML DevOps workflows (Kubernetes / Docker Compose)
          "lua_ls",       -- Lua syntax engine (Neovim IDE configuration)
          "dockerls",     -- Dockerfile inspection
          "html",         -- Web structure
          "cssls",        -- CSS visual rules
        },
        automatic_installation = true,
      })

      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Global LSP Keybindings & Autocmd execution hooks
      local on_attach = function(_, bufnr)
        local opts = { noremap = true, silent = true, buffer = bufnr }
        local map = vim.keymap.set
        
        map("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration", buffer = bufnr })
        map("n", "gd", vim.lsp.buf.definition,  { desc = "Go to definition", buffer = bufnr })
        map("n", "K",  vim.lsp.buf.hover,       { desc = "Display symbol hover document", buffer = bufnr })
        map("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation", buffer = bufnr })
        map("n", "<C-k>", vim.lsp.buf.signature_help, { desc = "Display function signature", buffer = bufnr })
        map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename code symbol across workspace", buffer = bufnr })
        map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Execute suggested LSP code action", buffer = bufnr })
        map("n", "gr", vim.lsp.buf.references,  { desc = "List code references", buffer = bufnr })
        map("n", "[d", vim.diagnostic.goto_prev, { desc = "Jump to previous diagnostic warning/error", buffer = bufnr })
        map("n", "]d", vim.diagnostic.goto_next, { desc = "Jump to next diagnostic warning/error", buffer = bufnr })
      end

      -- Configure individual language servers with shared capabilities & hooks
      local servers = { "bashls", "pyright", "ts_ls", "jsonls", "yamlls", "dockerls", "html", "cssls" }
      for _, server in ipairs(servers) do
        lspconfig[server].setup({
          on_attach = on_attach,
          capabilities = capabilities,
        })
      end

      -- Special optimization for Neovim Lua API intelligence
      lspconfig.lua_ls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false, library = vim.api.nvim_get_runtime_file("", true) },
            telemetry = { enable = false },
          },
        },
      })

      -- Configure visual diagnostic rendering in gutter & floating tooltips
      vim.diagnostic.config({
        virtual_text = { prefix = "●", source = "if_many" },
        float = { border = "rounded", source = "always", header = "", prefix = "" },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      -- Define custom Nerd Font signs in gutter
      local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
      end
    end,
  },

  -- ---------------------------------------------------------------------------
  -- 2. NVIM-CMP // Intelligent Code Completion Architecture
  -- ---------------------------------------------------------------------------
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      -- Icon rendering setup for autocompletion popup list
      local kind_icons = {
        Text = "󰉿", Method = "󰆧", Function = "󰊕", Constructor = "",
        Field = "󰜢", Variable = "󰀫", Class = "󰠱", Interface = "",
        Module = "", Property = "󰜢", Unit = "󰑭", Value = "󰎠",
        Enum = "", Keyword = "󰌋", Snippet = "", Color = "󰏘",
        File = "󰈙", Reference = "󰈇", Folder = "󰉋", EnumMember = "",
        Constant = "󰏿", Struct = "󰙅", Event = "", Operator = "󰆕",
        TypeParameter = "󰊄",
      }

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        window = {
          completion = cmp.config.window.bordered({
            border = "rounded",
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
          }),
          documentation = cmp.config.window.bordered({
            border = "rounded",
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
          }),
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = false }), -- Only confirm explicitly highlighted item
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        formatting = {
          fields = { "kind", "abbr", "menu" },
          format = function(entry, vim_item)
            vim_item.kind = string.format("%s", kind_icons[vim_item.kind])
            vim_item.menu = ({
              nvim_lsp = "[LSP]",
              luasnip  = "[Snippet]",
              buffer   = "[Buffer]",
              path     = "[Path]",
            })[entry.source.name]
            return vim_item
          end,
        },
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },
}
