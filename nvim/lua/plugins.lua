return require("lazy").setup({
  -- Add plugins here like this:
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate"
  },
  "tpope/vim-surround",
  "nvim-lualine/lualine.nvim",
  "nvim-tree/nvim-tree.lua",
  "nvim-tree/nvim-web-devicons",
  "folke/tokyonight.nvim",
})

