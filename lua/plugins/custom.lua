-- lua/plugins/custom.lua
return {
  -- TypeScript LSP, ESLint, and general LSP configuration
  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    config = function()
      -- Configure typescript-tools.nvim
      require("typescript-tools").setup({
        settings = {
          tsserver_max_memory = 8192, -- Increase memory limit if needed
          tsserver_watchOptions = {
            "useFsEvents", -- Use file system events for faster updates
            "fallbackPolling", -- Fallback to polling if needed
            "usePolling", -- Use polling as a last resort
          },
        },
        on_attach = function(client, bufnr)
          -- Disable tsserver formatting to let ESLint handle it
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false

          -- Set up ESLintFixAll command
          if client.server_capabilities.codeActionProvider then
            vim.api.nvim_buf_create_user_command(bufnr, "ESLintFixAll", function()
              vim.lsp.buf.code_action({
                context = {
                  only = { "source.fixAll.eslint" },
                  diagnostics = {},
                },
                bufnr = bufnr,
              })
            end, { desc = "Fix all ESLint issues" })
          end
        end,
      })
    end,
  },
  {
    "f-person/git-blame.nvim",
    config = function()
      vim.g.gitblame_enabled = 1 -- Enable git blame by default
    end,
  },
  -- ESLint setup via null-ls
  {
    "jose-elias-alvarez/null-ls.nvim",
    config = function()
      local null_ls = require("null-ls")

      -- Detect if the root has an ESLint config file
      local eslint_root_files = { ".eslintrc", ".eslintrc.js", ".eslintrc.json" }

      null_ls.setup({
        diagnostics_format = "[eslint] #{m}",
        update_in_insert = false,
        debounce = 1500,
        sources = {
          null_ls.builtins.diagnostics.eslint_d.with({
            condition = function(utils)
              return utils.root_has_file(eslint_root_files) -- Only enable if .eslintrc is found
            end,
          }),
          null_ls.builtins.formatting.eslint_d.with({
            condition = function(utils)
              return utils.root_has_file(eslint_root_files) -- Only enable if .eslintrc is found
            end,
          }),
          null_ls.builtins.code_actions.eslint_d.with({
            condition = function(utils)
              return utils.root_has_file(eslint_root_files) -- Only enable if .eslintrc is found
            end,
          }),
        },
        -- Root detection based on the closest .eslintrc file
        root_dir = require("null-ls.utils").root_pattern(".eslintrc", ".eslintrc.js", ".eslintrc.json", ".git"),
      })
    end,
  },

  -- Key mapping to run ESLintFixAll
  config = function()
    -- Key mapping for ESLintFixAll
    vim.api.nvim_set_keymap("n", "<C-S-T>", ":ESLintFixAll<CR>", { noremap = true, silent = true })
  end, -- Custom command to run ESLint manually via terminal
  {
    "glepnir/lspsaga.nvim",
    event = "BufRead",
    config = function()
      require("lspsaga").setup({
        -- Optional config for lspsaga
        lightbulb = {
          enable = false, -- Disable code action lightbulb
        },
        symbol_in_winbar = {
          enable = true, -- Show symbols in the window bar
        },
      })
    end,
  },
  {
    "ellisonleao/dotenv.nvim",
    config = function()
      require("dotenv").setup({
        enable_on_load = true, -- automatically load .env files
        verbose = false, -- show error notification if .env file is not found
      })

      -- Set up autocmd for .env files
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
        pattern = { ".env*" },
        callback = function()
          -- Enable syntax highlighting
          vim.cmd("setlocal syntax=sh")

          -- Set up folding for lines containing "SECRET" or "KEY"
          vim.cmd([[
            setlocal foldmethod=expr
            setlocal foldexpr=getline(v:lnum)=~'SECRET\\\|KEY'?'>1':'='
          ]])

          -- Define custom highlighting for secret variables
          vim.cmd([[
            highlight SecretVar guifg=#FF5555
            match SecretVar /^.*\(SECRET\|KEY\).*$/
          ]])

          -- Set up keybinding to toggle folds
          vim.api.nvim_buf_set_keymap(0, "n", "<Space>", "za", { noremap = true, silent = true })
        end,
      })
    end,
  },

  -- Telescope for fuzzy finding and search
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      telescope.setup({
        defaults = {
          path_display = { "smart" },
          dynamic_preview_title = true,
          prompt_prefix = " ",
          selection_caret = " ",
          file_ignore_patterns = {
            "node_modules",
            "%.ts%.html$",
            "test-results",
            ".nx",
            "%.git",
            "%.cache",
            "%.xml",
            "**/dist/*",
            "%.js.map",
          },
          mappings = {
            i = {
              ["<C-j>"] = "move_selection_next",
              ["<C-k>"] = "move_selection_previous",
            },
          },
        },
        pickers = {
          find_files = {
            hidden = true,
            follow = true,
          },
        },
      })

      -- Custom function to search all files in the current working directory and its subdirectories
      local function search_all_files()
        require("telescope.builtin").find_files({
          hidden = true,
          find_command = {
            "rg",
            "--files",
            "--hidden",
            "--glob",
            "!**/.git/*",
            "--glob",
            "!**/.nx/*",
            "--glob",
            "!**/test-results/*",
            "--glob",
            "!**/dist/*",
            "--glob",
            "!**/coverage/*",
          },
          search_dirs = { vim.fn.getcwd() },
        })
      end
      local function search_and_replace()
        -- Get the search term
        local search_term = vim.fn.input("Search Term: ")
        if search_term == "" then
          print("No search term provided.")
          return
        end

        -- Use Telescope live_grep to search the entire project (includes hidden files)
        require("telescope.builtin").live_grep({
          default_text = search_term,
          additional_args = function()
            return {
              "--hidden",
              "--glob",
              "!**/.git/*",
              "--glob",
              "!**/test-results/*",
              "--glob",
              "!**/.nx/*",
              "--glob",
              "!**/.git/*",
              "--glob",
              "!**/dist/*",
              "!**/coverage/*",
            }
          end,
        })

        -- Wait for user input to complete the replacement operation
        vim.defer_fn(function()
          local replace_term = vim.fn.input("Replace Term: ")
          if replace_term == "" then
            print("No replace term provided.")
            return
          end

          -- Replace all matches in the quickfix list
          vim.cmd(
            "cfdo %s/" .. vim.fn.escape(search_term, "/") .. "/" .. vim.fn.escape(replace_term, "/") .. "/gc | update"
          )
        end, 500) -- Wait for 500 ms to ensure the Telescope quickfix list is ready
      end

      -- Set up a keybinding for this function
      vim.keymap.set("n", "<leader>fr", search_and_replace, { noremap = true, silent = true })

      -- Key mappings
      vim.api.nvim_set_keymap("n", "<leader>ff", "<cmd>lua search_all_files()<CR>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap(
        "n",
        "<leader>fb",
        "<cmd>lua require('telescope.builtin').buffers()<CR>",
        { noremap = true, silent = true }
      )
      vim.api.nvim_set_keymap("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", { noremap = true, silent = true })
      -- Keep other existing key mappings...
    end,
  }, -- Telescope FZF for better fuzzy searching
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make", -- Required for compiling FZF native
    config = function()
      require("telescope").load_extension("fzf")
    end,
  },

  -- Treesitter for better syntax highlighting, indentation, and code understanding
  {
    "nvim-treesitter/nvim-treesitter",
    run = ":TSUpdate",
    opts = {
      ensure_installed = { "typescript", "javascript", "tsx", "lua", "json", "yaml", "terraform", "helm" },
      highlight = { enable = true },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = "<nop>",
          node_decremental = "<bs>",
        },
      },
    },
  },

  -- Jest test runner integration
  -- Jest test runner integration
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-neotest/nvim-nio",
      "haydenmeade/neotest-jest",
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-jest")({
            jestCommand = "yarn jest",
            cwd = function(path)
              return vim.fn.getcwd()
            end,
          }),
        },
      })

      -- Key mappings for neotest functions
      vim.api.nvim_set_keymap(
        "n",
        "<leader>t",
        '<cmd>lua require("neotest").run.run()<cr>',
        { noremap = true, silent = true }
      )
      vim.api.nvim_set_keymap(
        "n",
        "<leader>tt",
        '<cmd>lua require("neotest").run.run(vim.fn.expand("%"))<cr>',
        { noremap = true, silent = true }
      )
      vim.api.nvim_set_keymap(
        "n",
        "<leader>ts",
        '<cmd>lua require("neotest").summary.toggle()<cr>',
        { noremap = true, silent = true }
      )
      vim.api.nvim_set_keymap(
        "n",
        "<leader>to",
        '<cmd>lua require("neotest").output.open({ enter = true })<cr>',
        { noremap = true, silent = true }
      )
    end,
  }, -- Neo-tree for file explorer
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup({
        sources = { "filesystem", "buffers", "git_status", "document_symbols" },
        container = {
          enable_character_fade = false,
        },
        source_selector = {
          winbar = true,
          statusline = false,
          content_layout = "center",
          sources = {
            { source = "filesystem", display_name = " File" },
            { source = "buffers", display_name = "󰈙 Buffers" },
            { source = "git_status", display_name = "󰊢 Git" },
            { source = "document_symbols", display_name = " Symbols" },
          },
        },
        window = {
          width = 45,
        },
        filesystem = {
          filtered_items = {
            visible = true,
            hide_dotfiles = false,
            hide_gitignored = false,
          },
          follow_current_file = true,
          use_libuv_file_watcher = true,
        },

        default_component_configs = {
          name = {
            use_git_status_colors = true,
            highlight = "NeoTreeFileName",
            tooltip_enabled = true,
            tooltip = function(state, node)
              return node.path
            end,
            -- Add this to show full paths instead of just file names
            render = function(state, node)
              return node.path
            end,
          },
        },
      })

      -- Set up keymaps for Neo-tree
      vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>s", ":Neotree document_symbols<CR>", { noremap = true, silent = true })

      -- Set up a keymap for preview mode
      vim.keymap.set("n", "<leader>p", function()
        local node = require("neo-tree.sources.filesystem").get_node_under_cursor()
        if node and node.path then
          vim.cmd("edit " .. node.path)
        end
      end, { noremap = true, silent = true, desc = "Open selected file in a new buffer" })
    end,
  },
  -- Completion using nvim-cmp (for autocompletion)
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = {
          expand = function(args)
            vim.fn["vsnip#anonymous"](args.body) -- Use vsnip for snippets
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-d>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.close(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept with Enter
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "vsnip" },
          { name = "buffer" },
        }),
      })

      -- Command-line completion
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "path" },
          { name = "cmdline" },
        },
      })

      -- Search completion
      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })
    end,
  },

  -- Helm syntax highlighting
  {
    "towolf/vim-helm",
  },

  -- Terraform syntax highlighting and formatting
  {
    "hashivim/vim-terraform",
    config = function()
      vim.g.terraform_align = 1 -- Enable auto-align for terraform files
    end,
  },
  {
    "github/copilot.vim",
    event = "InsertEnter",
    config = function()
      vim.g.copilot_no_tab_map = true
      vim.g.copilot_assume_mapped = true
      vim.g.copilot_tab_fallback = ""
      vim.api.nvim_set_keymap("i", "<C-e>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
    end,
  },
  {
    "marko-cerovac/material.nvim",
    priority = 1000,
    config = function()
      require("material").setup({
        contrast = {
          sidebars = false,
          floating_windows = false,
        },
        styles = {
          comments = { italic = true },
          keywords = { bold = true },
          functions = { bold = true },
          strings = { italic = false },
          variables = {},
        },
        plugins = {
          "neo-tree",
          "nvim-cmp",
          "telescope",
          "which-key",
          "gitsigns",
        },
        custom_highlights = {
          LineNr = { fg = "#8a8a8a" },
          CursorLineNr = { fg = "#ffd966" },
          Identifier = { fg = "#ff5555" }, -- Bright red for variables/identifiers
          TSVariable = { fg = "#ff5555" }, -- Bright red for variables
          Function = { fg = "#e5c07b" },
          TSFunction = { fg = "#e5c07b" }, -- Treesitter function highlight
          TSProperty = { fg = "#ffffff" },
          TSField = { fg = "#ffffff" },
          TSComment = { fg = "#5c5c6b", italic = true }, -- Softer color for comments
          NormalNC = { bg = "#2c3643", fg = "#a0a0a0" }, -- Darker gray for unfocused windows
          TabLine = { bg = "#2c3643", fg = "#a0a0a0" }, -- Darker gray for unfocused tabs
          TabLineFill = { bg = "#2c3643" },
          TabLineSel = { bg = "#0d2137", fg = "#f0f0f0" },
          ["@property"] = { fg = "#ffffff" }, -- Set object properties to white
          ["@variable"] = { fg = "#ff5555" }, -- Keep variables bright red
        },
        custom_colors = function(colors)
          colors.editor.background = "#0d2137" -- Deep ocean blue
          colors.editor.foreground = "#f0f0f0"
          colors.syntax.comments = "#5c5c6b" -- Softer gray for comments
          colors.syntax.functions = "#61afef"
          colors.syntax.keywords = "#c678dd"
          colors.syntax.strings = "#98c379"
          colors.syntax.variables = "#ff5555"
          colors.syntax.numbers = "#d19a66"
          colors.syntax.constants = "#56b6c2"
          colors.syntax.operators = "#abb2bf"
        end,
      })
      vim.cmd("colorscheme material")

      vim.cmd([[
      hi Normal guibg=#0d2137 guifg=#f0f0f0
      hi SignColumn guibg=#0d2137
      hi VertSplit guifg=#505050 guibg=#0d2137
      hi StatusLine guibg=#0d2137 guifg=#61afef
      hi StatusLineNC guibg=#0d2137 guifg=#64748b
      hi Keyword guifg=#c678dd gui=bold
      hi Constant guifg=#56b6c2
      hi Identifier guifg=#ff5555 
      hi Function guifg=#61afef gui=bold
      hi String guifg=#98c379
      hi Number guifg=#d19a66
      hi Boolean guifg=#56b6c2
      hi Operator guifg=#abb2bf
      hi Delimiter guifg=#abb2bf
      hi Bracket guifg=#abb2bf
      hi Punctuation guifg=#abb2bf
      hi ParenMatch guifg=#0d2137 guibg=#61afef
      hi MatchParen guifg=#0d2137 guibg=#c678dd
      hi TypeHint guifg=#56b6c2
      hi Parameter guifg=#ffffff 
      hi Class guifg=#e5c07b gui=bold
      hi Property guifg=#ffffff 
      hi Method guifg=#61afef
      hi Special guifg=#56b6c2
      hi Tag guifg=#c678dd
      hi Attribute guifg=#61afef
      hi Statement guifg=#c678dd gui=bold
      hi Conditional guifg=#c678dd gui=bold
      hi Repeat guifg=#c678dd gui=bold
      hi Label guifg=#c678dd
      hi Exception guifg=#c678dd
      hi PreProc guifg=#c678dd
      hi Include guifg=#c678dd
      hi Define guifg=#c678dd
      hi Macro guifg=#c678dd
      hi Type guifg=#e5c07b gui=bold
      hi StorageClass guifg=#e5c07b
      hi Structure guifg=#e5c07b
      hi Typedef guifg=#e5c07b
      hi SpecialChar guifg=#56b6c2
      hi SpecialComment guifg=#64748b
      hi Error guifg=#ff5555 guibg=NONE
      hi Todo guifg=#e5c07b guibg=NONE gui=bold
      hi Underlined gui=underline
      hi TSParameter guifg=#ffffff 
      hi TSField guifg=#ffffff 
      hi TSProperty guifg=#ffffff 
      hi TSVariable guifg=#ff5555 
    ]])
    end,
  },
  {
    "nvim-tree/nvim-web-devicons",
    config = function()
      require("nvim-web-devicons").setup({
        -- You can customize icon colors here
        override = {
          ts = {
            icon = "",
            color = "#007acc",
            name = "Ts",
          },
          -- Add more file type overrides as needed
        },
        default = true,
      })
    end,
  },
  {
    "prisma/vim-prisma", -- Plugin for Prisma syntax highlighting
    ft = "prisma", -- Load only for `.prisma` files
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {
      indent = { char = "▏" },
      scope = { enabled = true },
    },
  },

  -- Git signs in the gutter
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },

  -- Color highlighter
  {
    "norcalli/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup()
    end,
  },
  {
    "Pocco81/auto-save.nvim",
    config = function()
      require("auto-save").setup()
    end,
  },
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()

      -- Custom key mappings for commenting
      vim.api.nvim_set_keymap("n", "<leader>cc", "gcc", { noremap = false, silent = true }) -- Comment a single line in normal mode
      vim.api.nvim_set_keymap("v", "<leader>cc", "gc", { noremap = false, silent = true }) -- Comment selected lines in visual mode

      vim.api.nvim_set_keymap("n", "<leader>cb", "gbc", { noremap = false, silent = true }) -- Comment block in normal mode
      vim.api.nvim_set_keymap("v", "<leader>cb", "gc", { noremap = false, silent = true }) -- Comment block in visual mode
    end,
  },
  {
    "kdheepak/lazygit.nvim",
    config = function()
      vim.keymap.set("n", "<leader>lg", ":LazyGit<CR>", { noremap = true, silent = true })
    end,
  },
}
