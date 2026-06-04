package.preload["snacks.deactivate"] = package.preload["snacks.deactivate"]
	or function()
		return function() end
	end

return {
	{
		"folke/snacks.nvim",
		opts = function(_, opts)
			opts.picker = opts.picker or {}
			opts.picker.sources = opts.picker.sources or {}
			opts.picker.sources.files = vim.tbl_deep_extend("force", opts.picker.sources.files or {}, {
				hidden = true,
			})
			opts.picker.sources.explorer = vim.tbl_deep_extend("force", opts.picker.sources.explorer or {}, {
				hidden = true,
				layout = {
					preset = "right",
				},
			})
		end,
	},
	{
		"nvim-mini/mini.pairs",
		event = "VeryLazy",
		opts = {
			modes = { insert = true, command = true, terminal = false },
			skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
			skip_ts = { "string" },
			skip_unbalanced = true,
			markdown = true,
		},
		config = function(_, opts)
			LazyVim.mini.pairs(opts)
		end,
	},
}
