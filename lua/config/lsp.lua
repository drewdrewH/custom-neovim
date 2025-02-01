-- lua/config/lsp.lua

local M = {}

--------------------------------------------------------------------------------
-- 1) Basic on_attach function used by all LSP servers
--------------------------------------------------------------------------------
function M.on_attach(client, bufnr)
  -- Example buffer-local keymaps for LSP
  local opts = { noremap = true, silent = true, buffer = bufnr }

  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
  vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
  vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
  vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

  -- If you rely on null-ls for formatting, disable TSServer's formatting:
  if client.name == "tsserver" then
    client.server_capabilities.documentFormattingProvider = false
  end

  -- Add any other server-specific logic here if you want to do it universally
  -- e.g., custom inlay hints, code lens disabling, etc.
end

--------------------------------------------------------------------------------
-- 2) Optional: capabilities for nvim-cmp
--------------------------------------------------------------------------------
M.capabilities = vim.lsp.protocol.make_client_capabilities()
-- If you use nvim-cmp, do:
-- local cmp_nvim_lsp = require("cmp_nvim_lsp")
-- M.capabilities = cmp_nvim_lsp.default_capabilities(M.capabilities)

--------------------------------------------------------------------------------
-- 3) Setup each server: mason-lspconfig plus typescript-tools
--------------------------------------------------------------------------------
function M.setup_servers()
  local mason_lspconfig = require("mason-lspconfig")
  local lspconfig = require("lspconfig")

  -- By default, mason-lspconfig calls lspconfig[server].setup()
  -- for each server in ensure_installed. We can attach a global handler:
  mason_lspconfig.setup_handlers({
    -- The default handler for all servers (except those with custom override)
    function(server_name)
      -- If "tsserver" is installed by mason, we might NOT want to do
      -- lspconfig.tsserver.setup here because "typescript-tools" handles TS.
      -- So we skip "tsserver" in the default handler.
      if server_name == "tsserver" then
        return
      end

      lspconfig[server_name].setup({
        on_attach = M.on_attach,
        capabilities = M.capabilities,
      })
    end,

    -- Example of a custom handler for "lua_ls", if you want special settings
    ["lua_ls"] = function()
      lspconfig.lua_ls.setup({
        on_attach = M.on_attach,
        capabilities = M.capabilities,
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            -- ... other lua_ls settings
          },
        },
      })
    end,
  })
end

return M
