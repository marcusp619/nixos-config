return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ts_ls = {
          root_dir = function(path)
            local util = require("lspconfig.util")
            local matcher = util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git")
            return matcher(path) or vim.loop.cwd()
          end,
        },
      },
    },
  },
}
