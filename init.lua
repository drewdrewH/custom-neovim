-- init.lua

-- Set <space> as the leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Basic Neovim settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.updatetime = 5000
vim.o.guifont = "JetBrainsMonoNLNerdFont-ExtraBold.ttf"

-- Install Lazy.nvim if it's not installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Load LazyVim and Lazy.nvim configurations
require("config.lazy") -- This loads LazyVim setup

-- Keymappings
local function set_keymap(mode, lhs, rhs, opts)
  vim.keymap.set(mode, lhs, rhs, opts or { noremap = true, silent = true })
end

-- LSP and navigation keymaps
set_keymap("n", "<A-S>", "<cmd>Lspsaga peek_definition<CR>")
set_keymap("n", "<D-LeftMouse>", "<cmd>lua vim.lsp.buf.definition()<CR>")

-- Telescope keymaps
set_keymap("n", "<leader>gr", "<cmd>Telescope lsp_references<CR>")
set_keymap("n", "<leader>gd", "<cmd>Telescope lsp_definitions<CR>")
set_keymap("n", "<leader>gi", "<cmd>Telescope lsp_implementations<CR>")
set_keymap("n", "<leader>gw", "<cmd>Telescope lsp_workspace_symbols<CR>")

-- Buffer navigation
set_keymap("n", "<Tab>", "<cmd>BufferLineCycleNext<CR>")
set_keymap("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<CR>")

-- Diagnostics configuration
-- Diagnostics configuration

-- Simple error sign configuration
local signs = { Error = "" }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end
local function create_augroup(name, autocmds)
  local group = vim.api.nvim_create_augroup(name, { clear = true })
  for _, autocmd in ipairs(autocmds) do
    vim.api.nvim_create_autocmd(autocmd.events, {
      group = group,
      pattern = autocmd.pattern,
      callback = autocmd.callback,
    })
  end
end

-- Then update your autocommand definitions:

create_augroup("YankHighlight", {
  {
    events = "TextYankPost",
    pattern = "*",
    callback = function()
      vim.highlight.on_yank()
    end,
  },
})

-- Diagnostics configuration
vim.diagnostic.config({
  virtual_text = false,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },
})

-- Filter to show only errors in floats
create_augroup("DiagnosticFloat", {
  {
    events = "CursorHold",
    pattern = "*",
    callback = function()
      local line_diagnostics = vim.diagnostic.get(0, {
        severity = {
          min = vim.diagnostic.severity.ERROR,
          max = vim.diagnostic.severity.ERROR,
        },
      })
      if #line_diagnostics > 0 then
        vim.diagnostic.open_float(nil, {
          focusable = false,
          border = "rounded",
          source = "always",
          prefix = " ",
          scope = "line",
        })
      end
    end,
    3000,
  },
})
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.prisma",
  command = "set filetype=prisma",
})

-- Telescope configuration
local telescope = require("telescope")
local builtin = require("telescope.builtin")

_G.search_all_files = function()
  builtin.find_files({
    hidden = true,
    no_ignore = true,
    search_dirs = { vim.fn.getcwd() },
    previewer = false,
    layout_config = {
      height = 0.6,
    },
  })
end
_G.search_all_buffers = function()
  builtin.buffers({
    sort_mru = true,
    ignore_current_buffer = true,
  })
end

local function search_in_directory()
  local dir = vim.fn.input("Enter directory to search: ", "", "dir")
  if dir ~= "" then
    builtin.live_grep({ search_dirs = { dir } })
  end
end

set_keymap("n", "<leader>sd", search_in_directory)
