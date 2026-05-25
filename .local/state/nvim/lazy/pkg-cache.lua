return {version=12,pkgs={{file="lazy.lua",spec=function()
return {
  -- nui.nvim can be lazy loaded
  { "MunifTanjim/nui.nvim", lazy = true },
  {
    "folke/noice.nvim",
  },
}

end,source="lazy",dir="/home/claude/.local/share/nvim/lazy/noice.nvim",name="noice.nvim",},{file="community",spec={"nvim-lua/plenary.nvim",lazy=true,},source="lazy",dir="/home/claude/.local/share/nvim/lazy/plenary.nvim",name="plenary.nvim",},},}