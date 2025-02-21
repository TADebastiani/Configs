local ensure_installed = {
    "bash-language-server",
    "beautysh",
    "stylua",
    "lua-language-server",
    "tsserver",
    "gdtoolkit",
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
            local cmp_lsp = require("cmp_nvim_lsp")

            local capabilities = vim.tbl_deep_extend(
                "force",
                {},
                vim.lsp.protocol.make_client_capabilities(),
                cmp_lsp.default_capabilities()
            )

            require("mason-lspconfig").setup({
                ensure_installed,
                automatic_installation = {
                    exclude = { "jdtls" },
                },
                handlers = {
                    function(server)
                        local config = {
                            capabilities = capabilities,
                        }

                        if server == "gdscript" then
                            config = vim.tbl_deep_extend("keep", config, require("settings.lsp.gdscript"))
                        end

                        lspconfig[server].setup(config)
                    end,
                },
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        lazy = false,
        keys = {
            { "K", vim.lsp.buf.hover },
            { "<leader>ca", vim.lsp.buf.code_action, { "n", "v" } },
            { "<leader>gd", vim.lsp.buf.definition },
            { "<leader>gD", vim.lsp.buf.declaration },
            { "<leader>gi", vim.lsp.buf.implementation },
            { "<leader>rn", vim.lsp.buf.rename },
            { "<leader>e", vim.diagnostic.open_float },
        },
    },
    {
        "nvimtools/none-ls.nvim",
        config = function()
            local null_ls = require("null-ls")
            null_ls.setup({
                debug = true,
                sources = {
                    null_ls.builtins.formatting.stylua,

                    -- Javascript/Typescript
                    null_ls.builtins.diagnostics.eslint,
                    null_ls.builtins.formatting.prettier,
                },
                on_attach = on_attach,
            })
        end,
    },
}
