return {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					"lua_ls",
					"tsserver",
				},
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
			local lspconfig = require("lspconfig")
			lspconfig.lua_ls.setup({})
			lspconfig.tsserver.setup({})

			vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
			vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {})
		end,
	},
	{
		"hrsh7th/nvim-cmp",
		config = function()
			local cmp = require("cmp")
			local cmp_select_opt = {
				behavior = cmp.SelectBehavior.Select,
			}

			cmp.setup({
				mapping = cmp.mapping.preset.insert({
					["<C-y"] = cmp.mapping.confirm({ select = true }),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-p>"] = cmp.mapping.select_prev_item(cmp_select_opt),
					["<C-n>"] = cmp.mapping.select_next_item(cmp_select_opt),
				}),
			})
		end,
	},
	{
		"hrsh7th/cmp-nvim-lsp",
	},
	{
		"L3MON4D3/LuaSnip",
	},
}
