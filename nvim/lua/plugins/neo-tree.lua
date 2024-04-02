return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = { 
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  opts = {
    close_if_last_window = false,
    popup_border_style = "rounded",
    enable_git_status = true,
  },
  config = function()
    vim.keymap.set("n", "<C-n>", "<cmd>Neotree filesystem reveal left<CR>", {})
    vim.cmd("Neotree")
  end
}
