local lsp_zero = require('lsp-zero')
local cmp = require('cmp')


lsp_zero.on_attach(function(client, bufnr)
  -- see :help lsp-zero-keybindings
  -- to learn the available actions
  lsp_zero.default_keymaps({buffer = bufnr})
end)

-- preferences

lsp_zero.set_sign_icons({
	error = '',
	warn = '',
	hint = '',
	info = '',
})

-- setup keybindings

local cmp_select = {behavior = cmp.SelectBehavior.Select}
cmp.setup({
	mapping = cmp.mapping.preset.insert({
		-- Ctrl-Y to confirm selection
		['<C-y>'] = cmp.mapping.confirm({ select = true }),
		-- Ctrl-Space to trigger the completion menu
		['<C-Space>'] = cmp.mapping.complete(),
		-- Move Up/Down between items
		['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
		['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
	})
})

-- here you can setup the language servers 

lsp_zero.setup_servers({
	"cmake",
	"eslint",
	"jsonls",
	"tsserver",
	"svelte",
});

require'lspconfig'.lua_ls.setup{
	on_init = function(client)
		local path = client.workspace_folders[1].name
		if not vim.loop.fs_stat(path..'/.luarc.json') and not vim.loop.fs_stat(path..'/.luarc.jsonc') then
			client.config.settings = vim.tbl_deep_extend('force', client.config.settings, {
				Lua = {
					runtime = {
						-- Tell the language server which version of Lua you're using
						-- (most likely LuaJIT in the case of Neovim)
						version = 'LuaJIT'
					},
					-- Make the server aware of Neovim runtime files
					workspace = {
						checkThirdParty = false,
						library = {
							vim.env.VIMRUNTIME
							-- "${3rd}/luv/library"
							-- "${3rd}/busted/library",
						}
						-- or pull in all of 'runtimepath'. NOTE: this is a lot slower
						-- library = vim.api.nvim_get_runtime_file("", true)
					}
				}
			})

			client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
		end
		return true
	end
}

