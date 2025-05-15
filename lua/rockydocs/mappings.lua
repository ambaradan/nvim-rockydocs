--[[
    mappings.lua - Keybindings and command definitions

    Features:
    - MkDocs server control commands
    - Virtual environment management
    - Browser integration

    Dependencies:
    - Requires rockydocs.utils for environment utilities
    - Requires rockydocs.configs for system configuration

    Commands:
    1. RockyDocs*: Documentation system controls
    2. PyVenv*: Python virtualenv operations
    3. Open/Stop server functions

    License:
    Distributed under the MIT License.
    Full text at: https://opensource.org/licenses/MIT
]]

local mkdocs = require("rockydocs.main")
local venv = require("rockydocs.utils")

vim.api.nvim_create_user_command("RockyDocsSetup", mkdocs.rockydocs, {})
vim.api.nvim_create_user_command("RockyDocsServe", mkdocs.serve, {})
vim.api.nvim_create_user_command("RockyDocsServe", function(opts)
	-- Parse port from command arguments if provided
	local port = opts.args and tonumber(opts.args) or nil
	mkdocs.serve({ port = port })
end, {
	nargs = "?", -- Optional argument
	complete = function()
		-- Optional: Add port suggestion logic
		return { "8000", "8080", "8888" }
	end,
})
vim.api.nvim_create_user_command("RockyDocsStop", mkdocs.stop_serve, {})
-- Add browser open command
vim.api.nvim_create_user_command("RockyDocsOpen", function()
	venv.open_mkdocs_browser()
end, {})
vim.api.nvim_create_user_command("RockyDocsBuild", mkdocs.build, {})
vim.api.nvim_create_user_command("RockyDocsStatus", mkdocs.mkdocs_status, {})

vim.api.nvim_create_user_command("PyVenvCreate", venv.create, {})
vim.api.nvim_create_user_command("PyVenvActivate", venv.activate, {})
vim.api.nvim_create_user_command("PyVenvDeactivate", venv.deactivate, {})
vim.api.nvim_create_user_command("PyVenvStatus", function()
	vim.notify(venv.status(), vim.log.levels.INFO)
end, {})
vim.api.nvim_create_user_command("PyVenvRemove", venv.remove, {})
