local ensure_installed = {
--    "bash-language-server",
--    "beautysh",
    "stylua",
--    "lua-language-server",
--    "tsserver",
--    "gdtoolkit",
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
            local cmp_lsp = require("cmp_nvim_lsp")

            local capabilities = vim.tbl_deep_extend(
                "force",
                {},
                vim.lsp.protocol.make_client_capabilities(),
                cmp_lsp.default_capabilities()
            )

            vim.lsp.config("gdscript", {})

            require("mason-lspconfig").setup({
                ensure_installed = ensure_installed,
                automatic_installation = {
                    exclude = { "jdtls" },
                },
                formatters_by_ft = {
                    gdscript = { "gdformat" },
                },
                handlers = {
                    function(server) -- default
                        vim.lsp.config(server, {
                            capabilities = capabilities,
                        })
                    end,

                    ["lua_ls"] = function()
                        vim.lsp.config("lua_ls", {
                            capabilities = capabilities,
                            settings = {
                                Lua = {
                                    runtime = { version = "Lua 5.1" },
                                    diagnostics = {
                                        globals = { "bit", "vim", "it", "describe", "before_each", "after_each" },
                                    },
                                },
                            },
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
                log_level = "trace",
                diagnostic_config = {
                    float = {
                        focusable = false,
                        style = "minimal",
                        border = "rounded",
                        source = "always",
                        header = "",
                        prefix = "",
                    },
                },
                sources = {
                    null_ls.builtins.formatting.stylua,
                    -- Javascript/Typescript
                    --null_ls.builtins.diagnostics.eslint,
                    null_ls.builtins.formatting.prettier,
                    -- godot
                    null_ls.builtins.formatting.gdformat,
                },
            })
        end,
    },
}
