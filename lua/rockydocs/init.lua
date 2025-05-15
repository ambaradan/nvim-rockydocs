--[[
    init.lua - Core initialization and configuration

    Functions:
    - setup(opts): Merges user config with defaults and loads modules

    Responsibilities:
    1. Load and validate configuration
    2. Initialize required modules
    3. Prepare runtime environment

    Dependencies:
    - Requires rockydocs.configs for system configuration
    - Requires rockydocs.main for MkDocs operations
    - Requires rockydocs.mappings for keybindings and command definitions
    - Requires rockydocs.utils for environment utilities

    License:
    Distributed under the MIT License.
    Full text at: https://opensource.org/licenses/MIT
]]

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
