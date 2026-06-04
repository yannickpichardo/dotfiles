local features = require("config.features")

return {
	{
		"neovim/nvim-lspconfig",
		ft = { "swift", "objc", "objcpp", "c", "cpp" },
		enabled = function()
			return features.lang.swift and (vim.fn.executable("sourcekit-lsp") == 1 or vim.fn.executable("xcrun") == 1)
		end,
		init = function()
			if not features.lang.swift then
				return
			end

			local function xcode_root(buf)
				local file = vim.api.nvim_buf_get_name(buf or 0)
				if file == "" then
					file = vim.uv.cwd() or vim.fn.getcwd()
				end
				local path = vim.fs.dirname(file) or file
				local markers = vim.fs.find({ "*.xcworkspace", "*.xcodeproj" }, { path = path, upward = true, limit = 1 })
				if #markers == 0 then
					return nil
				end
				return vim.fs.dirname(markers[1])
			end

			local function xcode_container(root)
				local workspaces = vim.fn.globpath(root, "*.xcworkspace", false, true)
				if #workspaces > 0 then
					return "-workspace", vim.fs.basename(workspaces[1])
				end

				local projects = vim.fn.globpath(root, "*.xcodeproj", false, true)
				if #projects > 0 then
					return "-project", vim.fs.basename(projects[1])
				end
			end

			vim.api.nvim_create_user_command("XcodeBuildServerConfig", function(cmd)
				local root = xcode_root(0)
				if not root then
					vim.notify("No .xcworkspace or .xcodeproj found for the current buffer", vim.log.levels.ERROR)
					return
				end

				local mode, target = xcode_container(root)
				if not mode or not target then
					vim.notify("Could not determine the Xcode workspace or project to configure", vim.log.levels.ERROR)
					return
				end

				local exe = vim.fn.exepath("xcode-build-server")
				if exe == "" then
					vim.notify("xcode-build-server is not installed. Install it first.", vim.log.levels.ERROR)
					return
				end

				local args = { exe, "config", mode, target }
				if cmd.args ~= "" then
					vim.list_extend(args, { "-scheme", cmd.args })
				end

				vim.system(args, { cwd = root }, function(result)
					vim.schedule(function()
						if result.code == 0 then
							vim.notify("Generated buildServer.json in " .. root, vim.log.levels.INFO)
						else
							local stderr = (result.stderr or ""):gsub("%s+$", "")
							vim.notify(stderr ~= "" and stderr or "xcode-build-server config failed", vim.log.levels.ERROR)
						end
					end)
				end)
			end, {
				nargs = "?",
				desc = "Generate buildServer.json for the current Xcode project",
			})
		end,
		opts = function(_, opts)
			opts.servers = opts.servers or {}

			local function sourcekit_cmd()
				local direct = vim.fn.exepath("sourcekit-lsp")
				if direct ~= "" then
					return { direct }
				end

				if vim.fn.executable("xcrun") == 1 then
					local resolved = vim.fn.systemlist({ "xcrun", "--find", "sourcekit-lsp" })[1]
					if vim.v.shell_error == 0 and resolved and resolved ~= "" then
						return { resolved }
					end
				end

				return { "sourcekit-lsp" }
			end

			opts.servers.sourcekit = vim.tbl_deep_extend("force", opts.servers.sourcekit or {}, {
				mason = false,
				cmd = sourcekit_cmd(),
				filetypes = { "swift", "objc", "objcpp", "c", "cpp" },
				root_dir = function(bufnr, on_dir)
					local util = require("lspconfig.util")
					local filename = vim.api.nvim_buf_get_name(bufnr)
					on_dir(
						util.root_pattern("buildServer.json", ".bsp")(filename)
							or util.root_pattern("*.xcodeproj", "*.xcworkspace")(filename)
							or util.root_pattern("compile_commands.json", ".sourcekit-lsp", "Package.swift")(filename)
							or vim.fs.dirname(vim.fs.find(".git", { path = filename, upward = true })[1])
					)
				end,
				settings = {
					swift = {
						["sourcekit-lsp"] = {
							backgroundIndexing = "on",
						},
					},
				},
			})
		end,
	},
}
