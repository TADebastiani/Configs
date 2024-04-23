local ensure_installed = {
    "bashls",
    "beautysh",
    "stylua",
    "lua_ls",
    "tsserver",
}

return {
    {
        "williamboman/mason.nvim",
        lazy = false,
        priority = 100,
        config = function()
            require("mason").setup()
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        lazy = false,
        config = function()
            local lspconfig = require("lspconfig")
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            require("mason-lspconfig").setup({
                ensure_installed,
                handlers = {
                    function(server)
                        lspconfig[server].setup({
                            capabilities = capabilities,
                        })
                    end,
                },
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        lazy = false,
        keys = {
            { "K",          vim.lsp.buf.hover },
            { "<leader>ca", vim.lsp.buf.code_action,   { "n", "v" } },
            { "<leader>gd", vim.lsp.buf.definition },
            { "<leader>gD", vim.lsp.buf.declaration },
            { "<leader>gi", vim.lsp.buf.implementation },
            { "<leader>rn", vim.lsp.buf.rename },
            { "<leader>e",  vim.diagnostic.open_float },
        },
    },
}
