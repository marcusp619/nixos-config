return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      vtsls = {
        root_dir = function(fname)
          return require("lspconfig.util").root_pattern("tsconfig.json", "package.json", "jsconfig.json", ".git")(fname)
        end,
      },
    },
  },
}
