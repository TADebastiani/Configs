local ensure_installed = {
    "bashls",
    "beautysh",
    "stylua",
    "lua_ls",
    "tsserver",
    "jdtls",
}

return {
    {
        "williamboman/mason.nvim",
        lazy = false,
        priority = 100,
        config = function()
            require("mason").setup()
            -- require("mason").setup({
            --     registries = {
            --         --"github:mason-org/mason-registry",
            --         "file:~/.config/nvim/lua/settings/mason-registry",
            --     },
            -- })
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = {
            "mfussenegger/nvim-jdtls",
        },
        lazy = false,
        config = function()
            local lspconfig = require("lspconfig")
            local cmp_lsp = require("cmp_nvim_lsp")
            local jdtls_settings = require("settings.lsp.jdtls")

            require("mason-lspconfig").setup({
                ensure_installed,
                automatic_installation = true,
                handlers = {
                    function(server)
                        local capabilities = vim.lsp.protocol.make_client_capabilities()
                        capabilities.textDocument.completion.completionItem.snippetSupport = true

                        local config = {
                            capabilities = cmp_lsp.default_capabilities(capabilities),
                        }

                        if server == "jdtls" then
                            config = vim.tbl_deep_extend("keep", config, jdtls_settings.get_config())
                        else
                            config.on_attach = function(client)
                                vim.print(client)
                                vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
                            end
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
}
