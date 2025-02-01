-- lua/plugins/custom.lua
return {
  {
    "vim-ruby/vim-ruby",
    ft = { "ruby", "eruby", "rake", "rb" },
    init = function()
      vim.g.ruby_indent_assignment_style = "variable"
    end,
  },
  -- RuboCop integration
  {
    "ngmy/vim-rubocop",
    ft = { "ruby", "eruby", "rake", "rb" },
    cmd = "RuboCop",
  },
  -- Ruby LSP
  -- Optional: Rails support
  {
    "tpope/vim-rails",
    ft = { "ruby", "eruby", "rake", "rb" },
  },
  -- Optional: End-wise (automatically add 'end' in Ruby)
  {
    "tpope/vim-endwise",
    ft = { "ruby", "eruby", "rake", "rb" },
  },
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate", -- This updates registries on install
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        -- Add the servers you use here
        ensure_installed = {
          "tsserver",
          "eslint",
          "lua_ls", -- if you want LSP for Lua
          "jsonls",
          "yamlls",
        },
        automatic_installation = true, -- auto-install if missing
      })
    end,
  }, -- TypeScript LSP, ESLint, and general LSP configuration
  {
    "pmizio/typescript-tools.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "neovim/nvim-lspconfig",
    },
    config = function()
      require("typescript-tools").setup({
        on_attach = function(client, bufnr)
          -- Enable document formatting
          vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

          -- Add keybindings
          local opts = { noremap = true, silent = true, buffer = bufnr }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          -- Keep your existing ESLint mapping
          vim.api.nvim_set_keymap("n", "<C-S-T>", ":ESLintFixAll<CR>", { noremap = true, silent = true })
        end,

        settings = {
          -- Maintain your existing settings
          separate_diagnostic_server = true,
          publish_diagnostic_on = "save_only",
          expose_as_code_action = "all", -- This will expose all code actions

          -- Improved completion and preview settings
          tsserver_file_preferences = {
            includeCompletionsForModuleExports = true,
            includeCompletionsForImportStatements = true,
            includeCompletionsWithSnippetText = true,
            includeAutomaticOptionalChainCompletions = true,
            includeCompletionsWithInsertText = true,
            includeCompletionsWithObjectLiteral = true,
            includeInlayParameterNameHintsWhenArgumentMatchesName = false,
            includeInlayFunctionParameterTypeHints = false,
            includeInlayVariableTypeHints = false,
            includeInlayPropertyDeclarationTypeHints = false,
            includeInlayFunctionLikeReturnTypeHints = false,
          },

          tsserver_format_options = {
            allowIncompleteCompletions = true,
            allowRenameOfImportPath = true,
          },

          -- Memory and performance settings
          tsserver_max_memory = "auto",
          complete_function_calls = true,
          include_completions_with_insert_text = true,

          -- Code lens configuration
          code_lens = "all",
          disable_member_code_lens = true,

          -- JSX configuration
          jsx_close_tag = {
            enable = true,
            filetypes = { "javascriptreact", "typescriptreact" },
          },
        },

        handlers = {
          -- Keep your existing handlers if any
          -- You can add the filter_diagnostics here if needed
        },
      })

      -- Additional Commands Setup
      vim.api.nvim_create_user_command("TSToolsOrganizeImports", function()
        require("typescript-tools.api").organize_imports()
      end, {})

      vim.api.nvim_create_user_command("TSToolsFixAll", function()
        require("typescript-tools.api").fix_all()
      end, {})

      vim.api.nvim_create_user_command("TSToolsAddMissingImports", function()
        require("typescript-tools.api").add_missing_imports()
      end, {})

      vim.api.nvim_create_user_command("TSToolsRemoveUnused", function()
        require("typescript-tools.api").remove_unused()
      end, {})

      -- Optional: Add keymaps for commonly used commands
      local opts = { noremap = true, silent = true }
      vim.keymap.set("n", "<leader>tsi", ":TSToolsOrganizeImports<CR>", opts)
      vim.keymap.set("n", "<leader>tsf", ":TSToolsFixAll<CR>", opts)
      vim.keymap.set("n", "<leader>tsa", ":TSToolsAddMissingImports<CR>", opts)
      vim.keymap.set("n", "<leader>tsr", ":TSToolsRemoveUnused<CR>", opts)
      vim.diagnostic.config({
        underline = {
          severity = {
            min = vim.diagnostic.severity.ERROR,
          },
        },
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
      local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
      local eslint_root_files = { ".eslintrc", ".eslintrc.js", ".eslintrc.json" }

      -- Disable automatic code action requests
      vim.lsp.handlers["textDocument/codeAction"] = function(_, _, actions)
        if not actions then
          return
        end
        return actions
      end

      null_ls.setup({
        diagnostics_format = "[eslint] #{m}",
        update_in_insert = false,
        debounce = 2000,
        throttle = 1000,
        should_attach = function(bufnr)
          local file_type = vim.api.nvim_buf_get_option(bufnr, "filetype")
          -- Only attach to specific file types where we want ESLint
          return vim.tbl_contains({ "javascript", "typescript", "javascriptreact", "typescriptreact" }, file_type)
        end,
        sources = {
          null_ls.builtins.diagnostics.eslint_d.with({
            runtime_condition = function()
              return "node" -- This will use your system's Node version
            end,
            condition = function(utils)
              return utils.root_has_file(eslint_root_files)
            end,
            method = null_ls.methods.DIAGNOSTICS_ON_SAVE,
            timeout = 10000,
          }),
          null_ls.builtins.formatting.eslint_d.with({
            runtime_condition = function()
              return "node"
            end,
            condition = function(utils)
              return utils.root_has_file(eslint_root_files)
            end,
          }), -- Completely disable automatic code actions
          null_ls.builtins.code_actions.eslint_d.with({
            condition = function(utils)
              -- Only return true when explicitly requested via command
              return false
            end,
          }),
        },
        root_dir = require("null-ls.utils").root_pattern(unpack(eslint_root_files), ".git"),
        on_attach = function(client, bufnr)
          -- Disable code actions for this client
          client.server_capabilities.codeActionProvider = false

          if client.supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = augroup,
              buffer = bufnr,
              callback = function()
                if vim.api.nvim_buf_is_valid(bufnr) then
                  vim.lsp.buf.format({ bufnr = bufnr })
                end
              end,
            })
          end
        end,
      })

      -- Create a command to manually trigger ESLint fix
      vim.api.nvim_create_user_command("ESLintFix", function()
        vim.cmd("EslintFixAll")
      end, {})
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
          enable = true, -- Disable code action lightbulb
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
        enable_on_load = true,
        verbose = false,
      })

      -- Set up autocmd for .env files with corrected syntax
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
        pattern = { ".env*" },
        callback = function()
          -- Enable syntax highlighting
          vim.cmd("setlocal syntax=sh")

          -- Set up folding for lines containing "SECRET" or "KEY"
          vim.cmd([[
          setlocal foldmethod=expr
          setlocal foldexpr=getline(v:lnum)=~'SECRET\|KEY'?'>1':'='
        ]])

          -- Define custom highlighting for secret variables
          vim.cmd([[
          highlight SecretVar guifg=#FF5555
          match SecretVar /^.*\(SECRET\|KEY\).*$/
        ]])

          -- Set up keybinding to toggle folds
          vim.keymap.set("n", "<Space>", "za", { buffer = true, noremap = true, silent = true })
        end,
      })
    end,
  },
  {
    "saghen/blink.cmp",
    lazy = false,
    dependencies = {
      "rafamadriz/friendly-snippets", -- Optional: For snippet support
    },
    version = "v0.*",
    opts = {
      keymap = { preset = "default" }, -- Choose 'default', 'super-tab', or 'enter' based on your preference
      appearance = {
        use_nvim_cmp_as_default = true, -- Ensures compatibility with themes expecting nvim-cmp highlights
        nerd_font_variant = "mono", -- Adjusts icon alignment; use 'mono' or 'normal' as needed
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        cmdline = { "path", "cmdline" },
      },
    },
  },

  -- Telescope for fuzzy finding and search
  {
    "nvim-telescope/telescope.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release",
        config = function()
          require("telescope").load_extension("fzf")
        end,
      },
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")
      local pickers = require("telescope.pickers")
      local finders = require("telescope.finders")
      local conf = require("telescope.config").values

      -- Enhanced file search function
      local function search_all_files()
        require("telescope.builtin").find_files({
          hidden = true,
          find_command = {
            "rg",
            "--files",
            "--hidden",
            "--follow",
            "--no-ignore-vcs",
            "--threads",
            "8",
            "-g",
            "!**/.git/*",
            "-g",
            "!**/.nx/*",
            "-g",
            "!**/test-results/*",
            "-g",
            "!**/dist/*",
            "-g",
            "!**/coverage/*",
            "-g",
            "!**/node_modules/*",
            "-g",
            "!**/.next/*",
            "-g",
            "!**/.cache/*",
          },
          search_dirs = { vim.fn.getcwd() },
        })
      end

      -- Enhanced search and replace function
      local function search_and_replace()
        local search_term = vim.fn.input("Search Term: ")
        if search_term == "" then
          print("No search term provided.")
          return
        end

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
              "!**/dist/*",
              "--glob",
              "!**/coverage/*",
            }
          end,
        })

        vim.defer_fn(function()
          local replace_term = vim.fn.input("Replace Term: ")
          if replace_term == "" then
            print("No replace term provided.")
            return
          end
          vim.cmd(
            "cfdo %s/" .. vim.fn.escape(search_term, "/") .. "/" .. vim.fn.escape(replace_term, "/") .. "/gc | update"
          )
        end, 500)
      end

      -- Main Telescope configuration
      telescope.setup({
        defaults = {
          path_display = { "smart" },
          dynamic_preview_title = true,
          prompt_prefix = " ",
          selection_caret = " ",
          initial_mode = "insert",
          selection_strategy = "reset",
          sorting_strategy = "ascending",
          layout_strategy = "horizontal",
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
          mappings = {
            i = {
              ["<C-n>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-y>"] = actions.select_default,
              ["<C-s>"] = actions.select_horizontal,
              ["<C-v>"] = actions.select_vertical,
              ["<C-t>"] = actions.select_tab,
              ["<C-u>"] = actions.preview_scrolling_up,
              ["<C-d>"] = actions.preview_scrolling_down,
            },
          },
          file_ignore_patterns = {
            "node_modules",
            "coverage",
            "%migration.sql",
            "%.ts%.html$",
            "test-results",
            ".nx",
            "%.git",
            "%.cache",
            "%.xml",
            "**/dist/*",
            "%.js.map",
          },
          -- Performance optimizations
          file_sorter = require("telescope.sorters").get_fuzzy_file,
          generic_sorter = require("telescope.sorters").get_generic_fuzzy_sorter,
          buffer_previewer_maker = function(filepath, bufnr, opts)
            opts = opts or {}
            filepath = vim.fn.expand(filepath)
            vim.loop.fs_stat(filepath, function(_, stat)
              if not stat then
                return
              end
              if stat.size > 100000 then
                vim.schedule(function()
                  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "File too large to preview" })
                end)
                return
              end
              require("telescope.previewers").buffer_previewer_maker(filepath, bufnr, opts)
            end)
          end,
          cache_picker = {
            num_pickers = 5,
            limit_entries = 1000,
          },
        },
        pickers = {
          find_files = {
            hidden = true,
            follow = true,
            previewer = false,
            path_display = function(_, path)
              local tail = require("telescope.utils").path_tail(path)
              local parent = path:sub(1, -(#tail + 2))
              return string.format("%s (%s)", tail, parent)
            end,
          },
          live_grep = {
            previewer = true,
            only_sort_text = true,
          },
          buffers = {
            show_all_buffers = true,
            sort_mru = true,
            previewer = false,
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
      })

      -- Load FZF extension
      pcall(require("telescope").load_extension, "fzf")

      -- Keymap definitions for the cheatsheet
      local keymaps = {
        {
          category = "File Navigation",
          mappings = {
            { key = "<leader>ff", desc = "Find all files (including hidden)" },
            { key = "<leader>fb", desc = "Find open buffers" },
            { key = "<leader>fg", desc = "Live grep in project" },
            { key = "<leader>fr", desc = "Search and replace across files" },
            { key = "<leader>ch", desc = "Open this keymap cheatsheet" },
          },
        },
        {
          category = "Git Integration",
          mappings = {
            { key = "<leader>lg", desc = "Open LazyGit interface" },
          },
        },
        {
          category = "File Explorer",
          mappings = {
            { key = "<leader>e", desc = "Toggle Neo-tree file explorer" },
            { key = "<leader>p", desc = "Preview file under cursor" },
          },
        },
        {
          category = "Testing",
          mappings = {
            { key = "<leader>t", desc = "Run test under cursor" },
            { key = "<leader>tt", desc = "Run all tests in current file" },
            { key = "<leader>ts", desc = "Toggle test summary panel" },
            { key = "<leader>to", desc = "Open test output window" },
          },
        },
        {
          category = "Code Actions",
          mappings = {
            { key = "<C-S-T>", desc = "Run ESLint fix all" },
            { key = "<C-j>", desc = "Accept Copilot suggestion" },
            { key = "<leader>cc", desc = "Toggle line comment" },
            { key = "<leader>cb", desc = "Toggle block comment" },
          },
        },
        {
          category = "Telescope Navigation",
          mappings = {
            { key = "<C-n>", desc = "Move to next item" },
            { key = "<C-p>", desc = "Move to previous item" },
            { key = "<CR>", desc = "Select item" },
            { key = "<C-s>", desc = "Open in horizontal split" },
            { key = "<C-v>", desc = "Open in vertical split" },
          },
        },
      }

      -- Function to show the keymap cheatsheet
      local function show_keymaps()
        local formatted_keymaps = {}
        for _, category in ipairs(keymaps) do
          -- Add category header
          table.insert(formatted_keymaps, {
            value = "",
            display = string.format("═══ %s ═══", category.category),
            ordinal = category.category,
            kind = "category",
          })

          -- Add mappings for the category
          for _, mapping in ipairs(category.mappings) do
            table.insert(formatted_keymaps, {
              value = mapping.key,
              display = string.format("  %-16s │ %s", mapping.key, mapping.desc),
              ordinal = category.category .. " " .. mapping.desc,
              kind = "mapping",
            })
          end
        end

        pickers
          .new({
            prompt_title = "🔑 Keymap Cheatsheet",
            finder = finders.new_table({
              results = formatted_keymaps,
              entry_maker = function(entry)
                return {
                  value = entry.value,
                  display = entry.display,
                  ordinal = entry.ordinal,
                  kind = entry.kind,
                }
              end,
            }),
            sorter = conf.generic_sorter({}),
            layout_config = {
              width = 0.8,
              height = 0.8,
            },
            attach_mappings = function(prompt_bufnr, map)
              actions.select_default:replace(function()
                actions.close(prompt_bufnr)
              end)
              return true
            end,
          })
          :find()
      end

      -- Register the keymap cheatsheet as a Telescope extension
      telescope.register_extension({
        exports = {
          keymaps = show_keymaps,
        },
      })

      -- Set up all keymaps
      local keymap_opts = { noremap = true, silent = true }
      vim.keymap.set("n", "<leader>ff", search_all_files, keymap_opts)
      vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", keymap_opts)
      vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<CR>", keymap_opts)
      vim.keymap.set("n", "<leader>fr", search_and_replace, keymap_opts)
      vim.keymap.set("n", "<leader>ch", ":Telescope keymaps<CR>", keymap_opts)
    end,
  }, -- Telescope FZF for better fuzzy searching

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
      "s1n7ax/nvim-window-picker", -- Added for better window selection
    },
    config = function()
      -- First, set up window picker configuration
      require("window-picker").setup({
        autoselect_one = true,
        include_current = false,
        filter_rules = {
          bo = {
            filetype = { "neo-tree", "neo-tree-popup", "notify" },
            buftype = { "terminal", "quickfix" },
          },
        },
        other_win_hl_color = "#e35e4f",
      })

      -- Define the focus function for Neotree
      local function focus_neotree()
        local neotree_wins = {}
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local buf = vim.api.nvim_win_get_buf(win)
          local ft = vim.api.nvim_buf_get_option(buf, "filetype")
          if ft == "neo-tree" then
            table.insert(neotree_wins, win)
          end
        end

        if #neotree_wins == 0 then
          -- No Neotree window exists, create one
          vim.cmd("Neotree focus")
        else
          -- Neotree window exists, just focus it
          vim.api.nvim_set_current_win(neotree_wins[1])
        end
      end

      -- Main Neotree setup
      require("neo-tree").setup({
        sources = { "filesystem", "buffers", "git_status", "document_symbols" },

        -- Window management settings
        window = {
          width = 45,
          mappings = {
            ["l"] = "open", -- Changed from open_with_window_picker
            ["<cr>"] = "open", -- Changed from open_with_window_picker
            ["S"] = "split_with_window_picker",
            ["s"] = "vsplit_with_window_picker",
            ["w"] = "open_with_window_picker",
            ["h"] = "close_node",
            ["/"] = "fuzzy_finder",
            ["f"] = "filter_on_submit",
            ["<esc>"] = "clear_filter",
            ["a"] = { "add", config = { show_path = "relative" } },
          },
        },

        filesystem = {
          filtered_items = {
            visible = true,
            hide_dotfiles = false,
            hide_gitignored = false,
            hide_by_pattern = {
              --'*.meta',
              --'*/src/*/tsconfig.json',
            },
            always_show = { -- remains visible even if other settings would hide it
              ".gitignored",
              ".env*",
            },
          },
          follow_current_file = true,
          use_libuv_file_watcher = true,
          group_empty_dirs = true,

          window = {
            mappings = {
              ["<bs>"] = "navigate_up",
              ["."] = "set_root",
              ["H"] = "toggle_hidden",
              ["/"] = "fuzzy_finder",
              ["D"] = "fuzzy_finder_directory",
              ["#"] = "fuzzy_sorter",
              ["f"] = "filter_on_submit",
              ["<c-x>"] = "clear_filter",
              -- Additional navigation mappings
              ["gg"] = "goto_top",
              ["G"] = "goto_bottom",
              ["{"] = "prev_source",
              ["}"] = "next_source",
              ["<C-d>"] = "scroll_down",
              ["<C-u>"] = "scroll_up",
              ["gh"] = "goto_header",
            },
          },

          -- Special handling for certain file types
          commands = {
            open = function(state)
              local node = state.tree:get_node()
              local path = node:get_id()

              -- First check if it's a directory
              if node.type == "directory" then
                require("neo-tree.sources.filesystem.commands").open(state)
                return
              end

              -- For files, use the window picker
              require("neo-tree.sources.filesystem.commands").open_with_window_picker(state)
            end,

            open_with_window_picker = function(state)
              local node = state.tree:get_node()
              local path = node:get_id()

              -- Use the window-picker to select a window
              local success, selected_window = pcall(require("window-picker").pick_window)

              if success and selected_window then
                -- Switch to the selected window
                vim.api.nvim_set_current_win(selected_window)
                -- Open the file in that window
                vim.cmd("edit " .. vim.fn.fnameescape(path))
              else
                -- Fallback: open in current window if window picker fails
                vim.cmd("edit " .. vim.fn.fnameescape(path))
              end
            end,
          },
        },

        default_component_configs = {
          indent = {
            with_markers = true,
            indent_marker = "│",
            last_indent_marker = "└",
            indent_size = 2,
          },
          name = {
            use_git_status_colors = true,
            highlight = "NeoTreeFileName",
            highlight_opened_files = true,
          },
          git_status = {
            symbols = {
              added = "✚",
              deleted = "✖",
              modified = "",
              renamed = "󰁕",
              untracked = "",
              ignored = "",
              unstaged = "󰄱",
              staged = "",
              conflict = "",
            },
          },
        },
      })

      -- Map the focus function to <leader>e
      vim.keymap.set("n", "<leader>e", focus_neotree, { noremap = true, silent = true, desc = "Focus Neotree" })

      -- Set up autocommands for better window management
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "neo-tree",
        callback = function()
          -- Make Neo-tree buffer fixed size
          vim.cmd("setlocal winfixwidth")
        end,
      })

      -- Additional settings
      vim.g.neo_tree_remove_legacy_commands = 1

      -- Ensure dotfiles are always shown in buffer list
      vim.opt.wildignore:remove(".git")
      vim.opt.wildignore:remove("node_modules")
    end,
  },
  -- Completion using nvim-cmp (for autocompletion)

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
      vim.api.nvim_set_keymap("i", "<C-j>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
    end,
  },
  {
    "ellisonleao/gruvbox.nvim",
    opts = {
      transparent_mode = true,
    },
  },
  {
    "sainnhe/gruvbox-material",
    priority = 1000,
    lazy = false,
    config = function()
      vim.o.background = "dark"

      -- Configure base theme settings
      vim.g.gruvbox_material_background = "medium"
      vim.g.gruvbox_material_foreground = "mix"
      vim.g.gruvbox_material_ui_contrast = "high"
      vim.g.gruvbox_material_better_performance = 1
      vim.g.gruvbox_material_enable_bold = 1
      vim.g.gruvbox_material_enable_italic = 1
      vim.g.gruvbox_material_disable_italic_comment = 1
      vim.g.gruvbox_material_current_word = "bold"

      -- Base colors for UI elements
      vim.g.gruvbox_material_colors_override = {
        bg0 = { "#282c34", "235" }, -- One Dark inspired background
        bg1 = { "#2e323a", "236" },
        bg2 = { "#353b45", "237" },
        fg0 = { "#abb2bf", "254" }, -- One Dark text color
        fg1 = { "#9da5b4", "253" },
      }

      -- Apply the colorscheme
      vim.cmd("colorscheme gruvbox-material")

      -- UI element highlights
      vim.api.nvim_set_hl(0, "Normal", { bg = "#282c34", fg = "#abb2bf" })
      vim.api.nvim_set_hl(0, "NormalNC", { bg = "#24272e" })
      vim.api.nvim_set_hl(0, "CursorLine", { bg = "#2c313a" })
      vim.api.nvim_set_hl(0, "Visual", { bg = "#3e4451" })
      vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#528bff" })

      -- Syntax highlighting with more blue/purple tones
      vim.api.nvim_set_hl(0, "Comment", { fg = "#5c6370", italic = true })
      vim.api.nvim_set_hl(0, "Keyword", { fg = "#c678dd", bold = true }) -- Purple for keywords
      vim.api.nvim_set_hl(0, "Function", { fg = "#61afef", bold = true }) -- Blue for functions
      vim.api.nvim_set_hl(0, "String", { fg = "#98c379" }) -- Keep some green for strings
      vim.api.nvim_set_hl(0, "Number", { fg = "#d19a66" }) -- Soft orange for numbers
      vim.api.nvim_set_hl(0, "Operator", { fg = "#56b6c2" }) -- Cyan for operators
      vim.api.nvim_set_hl(0, "Type", { fg = "#e06c75" }) -- Soft red for types
      vim.api.nvim_set_hl(0, "Constant", { fg = "#be5046" }) -- Darker red for constants
      vim.api.nvim_set_hl(0, "Special", { fg = "#528bff" }) -- Bright blue for special chars
      vim.api.nvim_set_hl(0, "PreProc", { fg = "#c678dd" }) -- Purple for preprocessor
      vim.api.nvim_set_hl(0, "Identifier", { fg = "#61afef" }) -- Blue for identifiers
      vim.api.nvim_set_hl(0, "Statement", { fg = "#c678dd" }) -- Purple for statements
      vim.api.nvim_set_hl(0, "Boolean", { fg = "#56b6c2", bold = true }) -- Cyan for booleans

      -- Additional syntax highlights for specific code elements
      vim.api.nvim_set_hl(0, "TSProperty", { fg = "#61afef" }) -- Blue for properties
      vim.api.nvim_set_hl(0, "TSParameter", { fg = "#abb2bf" }) -- Default text for parameters
      vim.api.nvim_set_hl(0, "TSPunctDelimiter", { fg = "#56b6c2" }) -- Cyan for delimiters
      vim.api.nvim_set_hl(0, "TSVariable", { fg = "#e06c75" }) -- Soft red for variables
      vim.api.nvim_set_hl(0, "TSMethod", { fg = "#61afef", bold = true }) -- Blue for methods
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox-material",
    },
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
      require("auto-save").setup({
        enabled = true,
        trigger_events = {
          "InsertLeave",
          "TextChanged",
        },
        execution_message = {
          enabled = false,
        },
        write_all_buffers = false,
        debounce = {
          delay = 1000,
          check_interval = 1000,
        },
        condition = function(buf)
          local fn = vim.fn
          if fn.getbufvar(buf, "&filetype") == "TelescopePrompt" then
            return false
          end
          return true
        end,
      })
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
