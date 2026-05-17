return {
  "nyoom-engineering/oxocarbon.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    vim.opt.background = "dark" 
    vim.cmd.colorscheme "oxocarbon"
    
    -- Transparency for Foot
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })

    -- 1. Comments
    local comment_grey = "#888888"
    vim.api.nvim_set_hl(0, "Comment", { fg = comment_grey, italic = true })
    vim.api.nvim_set_hl(0, "@comment", { fg = comment_grey, italic = true })

    -- 2. Fix Hidden/Ignored files in Snacks Explorer & Picker
    vim.api.nvim_set_hl(0, "SnacksPickerPathHidden", { fg = comment_grey })
    vim.api.nvim_set_hl(0, "SnacksPickerPathIgnored", { fg = comment_grey })
    
    -- Optional: If the folder names themselves are also too dark
    -- vim.api.nvim_set_hl(0, "SnacksPickerDir", { fg = comment_grey })
  end,
}
