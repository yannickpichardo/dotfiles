local M = {}

local function env_bool(name, default)
	local value = vim.env[name]
	if value == nil or value == "" then
		return default
	end

	value = value:lower()
	return value == "1" or value == "true" or value == "yes" or value == "on"
end

M.lang = {
	python = env_bool("NVIM_ENABLE_PYTHON", true),
	swift = env_bool("NVIM_ENABLE_SWIFT", true),
}

local ok, local_config = pcall(require, "config.local")
if ok and type(local_config) == "table" then
	M = vim.tbl_deep_extend("force", M, local_config)
end

return M
