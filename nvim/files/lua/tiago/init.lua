require("tiago.packer")
require("tiago.remap")
require("tiago.set")

vim.cmd([[
augroup packer_user_config
    autocmd!
    autocmd BufWritePost packer.lua source <afile> | PackerSync
augroup end
]])

