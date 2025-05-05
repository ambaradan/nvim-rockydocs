-- lua/nvim-rockydocs/init.lua
local M = {}

-- Default configuration
local config = {
    port = "8000", -- Default port for mkdocs serve
}

-- Setup function
function M.setup(opts)
    opts = opts or {}
    config.port = opts.port or config.port -- Update the port if provided
end

-- Keep existing require calls
require("nvim-rockydocs.main")
require("nvim-rockydocs.utils")
require("nvim-rockydocs.mappings")

-- Expose the config for other modules
M.config = config

return M
