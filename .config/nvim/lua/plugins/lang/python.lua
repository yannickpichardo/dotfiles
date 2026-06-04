local features = require("config.features")

return {
	{
		"neovim/nvim-lspconfig",
		ft = "python",
		enabled = function()
			return features.lang.python
		end,
		opts = function(_, opts)
			opts.servers = opts.servers or {}

			opts.servers.ty = vim.tbl_deep_extend("force", opts.servers.ty or {}, {
				mason = true,
				settings = {
					ty = {
						diagnosticMode = "workspace",
					},
				},
			})

			opts.servers.pyright = vim.tbl_deep_extend("force", opts.servers.pyright or {}, {
				enabled = false,
			})

			opts.servers.basedpyright = vim.tbl_deep_extend("force", opts.servers.basedpyright or {}, {
				enabled = false,
			})

			opts.servers.ruff = vim.tbl_deep_extend("force", opts.servers.ruff or {}, {
				mason = true,
				init_options = {
					settings = {
						fixAll = true,
						logLevel = "error",
						organizeImports = true,
					},
				},
			})

			local existing_setup = opts.setup or {}
			opts.setup = vim.tbl_deep_extend("force", existing_setup, {
				ruff = function(server, server_opts)
					local handled = existing_setup.ruff and existing_setup.ruff(server, server_opts)
					if handled then
						return true
					end

					Snacks.util.lsp.on({ name = "ruff" }, function(_, client)
						client.server_capabilities.hoverProvider = false
					end)
				end,
			})
		end,
	},
	{
		"stevearc/conform.nvim",
		optional = true,
		ft = "python",
		enabled = function()
			return features.lang.python
		end,
		opts = function(_, opts)
			opts.formatters_by_ft = opts.formatters_by_ft or {}
			opts.formatters_by_ft.python = { "ruff_fix", "ruff_organize_imports", "ruff_format" }
		end,
	},
}
