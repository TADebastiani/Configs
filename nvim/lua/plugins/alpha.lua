return { 
  "goolord/alpha-nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = function()
    return require("alpha.themes.dashboard").config
  end
}
