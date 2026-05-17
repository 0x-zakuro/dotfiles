return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            hidden = true,  -- Shows dotfiles (.config) in the sidebar
            ignored = true, -- Optional: Shows gitignored files too
          },
          files = {
            hidden = true,  -- Shows dotfiles in <leader>ff
          },
        },
      },
    },
  },
}
