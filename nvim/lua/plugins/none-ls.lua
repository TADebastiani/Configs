return {
    "nvimtools/none-ls.nvim",
    config = function()
        local null_ls = require("null-ls")
        local custom_formatting = require("settings.formatting")
        null_ls.setup({
            debug = true,
            sources = {
                null_ls.builtins.formatting.stylua,
                -- Javascript/Typescript
                --null_ls.builtins.diagnostics.eslint,
                null_ls.builtins.formatting.prettier,
                custom_formatting.palantir,
            },
            on_attach = function(client)
                if client.supports_method("textDocument/formatting") then
                    vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
                end
            end,
        })

    end,
}
