return {
	"epwalsh/obsidian.nvim",
  enable = false,
	dependencies = {
		-- Required
		"nvim-lua/plenary.nvim",
		"hrsh7th/nvim-cmp",
		"nvim-telescope/telescope.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	opts = {
		workspaces = {
			{
				name = "default",
				path = "~/Documents/Obsidian",
			},
		},
		log_level = vim.log.levels.INFO,
		completion = {
			nvim_cmp = true,
			min_chars = 3,
		},
		picker = {
			name = "telescope.nvim",
		},
		note_id_func = function(title)
			return title
		end,
	},
	keys = {
		{ "<leader>oo", "<cmd>ObsidianOpen<CR>", desc = "Open file in Obsidian" },
		{ "<leader>os", "<cmd>ObsidianSearch<CR>" },
		{ "<leader>of", "<cmd>ObsidianFollowLink<CR>" },
	},
}
