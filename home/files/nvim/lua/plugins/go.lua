return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      -- gopls comes from Nix (common.nix), not Mason, so the terminal and
      -- the editor always run the exact same binary.
      gopls = { mason = false },
    },
  },
}
