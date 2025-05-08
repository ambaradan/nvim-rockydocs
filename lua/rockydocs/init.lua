local M = {}

function M.setup(opts)
	local configs = require("rockydocs.configs")

	-- Merge user options with defaults
	configs.config = vim.tbl_deep_extend("force", vim.deepcopy(configs.default_config), opts or {})

	-- Load plugin components
	require("rockydocs.main")
	require("rockydocs.utils")
	require("rockydocs.mappings")
end

return M
