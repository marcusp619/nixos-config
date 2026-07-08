-- Options (must come before lazy so leader is set before any plugin mappings)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.scrolloff = 8

-- ESC saves in normal mode
vim.keymap.set("n", "<Esc>", "<cmd>w<cr>", { desc = "Save" })

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {

    -- snacks.nvim: file picker, live grep, buffer switcher
    {
      "folke/snacks.nvim",
      priority = 1000,
      lazy = false,
      opts = {
        bigfile = { enabled = true },
        picker = { enabled = true },
        words = { enabled = true },
      },
      keys = {
        { "<leader><space>", function() Snacks.picker.smart() end,   desc = "Smart Find" },
        { "<leader>ff",      function() Snacks.picker.files() end,   desc = "Find Files" },
        { "<leader>fg",      function() Snacks.picker.grep() end,    desc = "Live Grep" },
        { "<leader>fb",      function() Snacks.picker.buffers() end, desc = "Buffers" },
        { "<leader>fr",      function() Snacks.picker.recent() end,  desc = "Recent" },
        { "<leader>fh",      function() Snacks.picker.help() end,    desc = "Help Pages" },
      },
    },

    -- oil.nvim: edit the filesystem like a buffer
    {
      "stevearc/oil.nvim",
      lazy = false,
      dependencies = { "nvim-tree/nvim-web-devicons" },
      opts = {},
      keys = {
        { "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
      },
    },

    -- neogit: full-featured git TUI
    {
      "NeogitOrg/neogit",
      dependencies = {
        "nvim-lua/plenary.nvim",
        "sindrets/diffview.nvim",
      },
      config = true,
      keys = {
        { "<leader>gg", "<cmd>Neogit<cr>", desc = "Neogit" },
      },
    },

    -- gitsigns: inline hunks and blame
    {
      "lewis6991/gitsigns.nvim",
      event = { "BufReadPre", "BufNewFile" },
      opts = {
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns
          local map = function(mode, l, r, desc)
            vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
          end
          map("n", "]h", gs.next_hunk,                                 "Next Hunk")
          map("n", "[h", gs.prev_hunk,                                 "Prev Hunk")
          map("n", "<leader>hs", gs.stage_hunk,                        "Stage Hunk")
          map("n", "<leader>hr", gs.reset_hunk,                        "Reset Hunk")
          map("n", "<leader>hp", gs.preview_hunk,                      "Preview Hunk")
          map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Blame Line")
        end,
      },
    },

    -- which-key: discoverable keybinding cheatsheet
    {
      "folke/which-key.nvim",
      event = "VeryLazy",
      opts = {},
    },

  },
  install = { colorscheme = { "habamax" } },
  checker = { enabled = false },
})
