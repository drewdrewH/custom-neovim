-- init.lua

-- Set <space> as the leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "
-- init.lua

-- Command-click for navigating to definition (class or function)
vim.api.nvim_set_keymap(
  "n",
  "<A-S>", -- Command + Click on Mac
  "<cmd>Lspsaga peek_definition<CR>", -- Show class definition in a modal
  { noremap = true, silent = true }
)
vim.api.nvim_set_keymap(
  "n",
  "<D-LeftMouse>",
  "<cmd>lua vim.lsp.buf.definition()<CR>",
  { noremap = true, silent = true }
)

-- Telescope key mappings for fuzzy search and LSP usage search
vim.api.nvim_set_keymap("n", "<leader>gr", "<cmd>Telescope lsp_references<CR>", { noremap = true, silent = true })

vim.api.nvim_set_keymap("n", "<leader>gd", "<cmd>Telescope lsp_definitions<CR>", { noremap = true, silent = true })

vim.api.nvim_set_keymap("n", "<leader>gi", "<cmd>Telescope lsp_implementations<CR>", { noremap = true, silent = true })

vim.api.nvim_set_keymap(
  "n",
  "<leader>gw",
  "<cmd>Telescope lsp_workspace_symbols<CR>",
  { noremap = true, silent = true }
)

-- Install Lazy.nvim if it's not installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable", -- Latest stable release
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Load LazyVim and Lazy.nvim configurations
require("config.lazy") -- This loads LazyVim setup
require("lazy").setup("plugins.custom") -- This loads your custom plugins

-- Basic Neovim settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true

-- Command-click for definition
vim.api.nvim_set_keymap(
  "n",
  "<D-LeftMouse>",
  "<cmd>lua vim.lsp.buf.definition()<CR>",
  { noremap = true, silent = true }
)

-- Diagnostics display setup
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  update_in_insert = false,
  underline = true,
  severity_sort = true,
  float = {
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },
})

-- Highlight on yank
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = "*",
})

vim.o.guifont = "JetBrainsMonoNLNerdFont-ExtraBold.ttf"
vim.diagnostic.config({
  virtual_text = false,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

local signs = { Error = "", Warn = "", Info = "", Hint = "" }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

vim.o.updatetime = 100

vim.api.nvim_create_autocmd("CursorHold", {
  buffer = vim.api.buffer,
  callback = function()
    local opts = {
      focusable = false,
      border = "rounded",
      source = "always",
      prefix = " ",
      scope = "line",
    }
    vim.diagnostic.open_float(nil, opts)
  end,
})

vim.api.nvim_create_autocmd({ "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" }, {
  group = vim.api.nvim_create_augroup("float_diagnostic", { clear = true }),
  callback = function()
    vim.diagnostic.open_float(nil, { focus = false })
  end,
})
vim.opt.termguicolors = true -- Enable 24-bit RGB color in the TUI
vim.cmd([[
  augroup FiletypePrisma
    autocmd!
    autocmd BufRead,BufNewFile *.prisma set filetype=prisma
  augroup END
]])
-- Add these lines near the end of your init.lua
_G.search_all_files = function()
  require("telescope.builtin").find_files({
    hidden = true,
    no_ignore = true,
    search_dirs = { vim.fn.getcwd() },
  })
end

_G.search_all_buffers = function()
  require("telescope.builtin").buffers({
    sort_mru = true,
    ignore_current_buffer = true,
  })
end
vim.api.nvim_set_keymap("n", "<Tab>", ":bnext<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<S-Tab>", ":bprevious<CR>", { noremap = true, silent = true })
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
  -- Increase debounce to control how often diagnostics are updated
  update_in_insert = false, -- Set to true if you want updates while typing in insert mode
  debounce = 100, -- Debounce time in milliseconds (lower value for quicker updates)
})
