return {
    "epwalsh/obsidian.nvim",
    enable = true,
    lazy = false,
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
                name = "personal",
                path = "~/Documentos/Obsidian/Vaults/personal",
            },
            {
                name = "compass",
                path = "~/Documentos/Obsidian/Vaults/compass",
            },
            {
                name = "vivo",
                path = "~/Documentos/Obsidian/Vaults/vivo",
            }
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
        { "<leader>oo", "<cmd>ObsidianOpen<CR>",      desc = "Open file in Obsidian" },
        { "<leader>os", "<cmd>ObsidianSearch<CR>" },
        { "<leader>of", "<cmd>ObsidianFollowLink<CR>" },
    },
    config = function(_, opts)
        require('obsidian').setup(opts)
        vim.opt.conceallevel = 1
    end
}
