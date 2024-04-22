return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    local config = require("nvim-treesitter.configs")
    config.setup({
      auto_install = true,
      sync_install = false,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false
      },
      ident = { enable = true },
    })
  end,
}