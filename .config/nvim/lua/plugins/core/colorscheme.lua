return {
	{
		"rockyzhang24/arctic.nvim",
		name = "arctic",
		dependencies = { "rktjmp/lush.nvim" },
		lazy = false,
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("arctic")

			local groups = {
				"@parameter",
				"@parameter.python",
				"@variable.parameter",
				"@variable.parameter.python",
				"@lsp.type.parameter",
				"@lsp.type.parameter.python",
				"@lsp.typemod.parameter.declaration",
				"@lsp.typemod.parameter.declaration.python",
			}
			for _, group in ipairs(groups) do
				vim.api.nvim_set_hl(0, group, { link = "Identifier" })
			end
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
		optional = true,
		opts = function(_, opts)
			opts.theme = "arctic"
		end,
	},
}
