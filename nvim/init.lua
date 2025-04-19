vim.schedule(function()
    vim.notify("✅ Neovim config loaded: " .. vim.fn.stdpath("config"))

    if vim.g.vscode then
        vim.notify("🟣 Running inside VSCode-Neovim")
    else
        vim.notify("🟢 Running in standalone Neovim")
    end
end)

-- Basic settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.clipboard = 'unnamedplus'
vim.opt.termguicolors = true

-- Keymap example
vim.keymap.set('n', '<Space>', '<Nop>', { silent = true })
vim.keymap.set('i', 'jj', '<Esc>', { noremap = true, silent = true })
vim.keymap.set('i', 'jk', '<Esc>:w<CR>', { noremap = true, silent = true })

-- VSCode-specific keymaps (optional)
if vim.g.vscode then
  local vscode = require("vscode")

  -- Example: <leader>ff opens file search in VSCode
  vim.keymap.set("n", "<Leader>ff", function()
    vscode.action("workbench.action.quickOpen")
  end, { silent = true })
end

-- Only load plugins and themes outside of VSCode
if not vim.g.vscode then
  -- Plugin manager (lazy.nvim)
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable", -- latest stable release
      lazypath,
    })
  end
  vim.opt.rtp:prepend(lazypath)

  -- Load plugins
  require("plugins")

  -- Set theme
  vim.cmd.colorscheme("tokyonight")
end

