-- File: mappings.lua
-- Description: File with Neovim commands and key mappings

local mkdocs = require("nvim-rockydocs.main")
local venv = require("nvim-rockydocs.utils")

vim.api.nvim_create_user_command("RockyDocsSetup", mkdocs.rockydocs, {})
vim.api.nvim_create_user_command("RockyDocsServe", mkdocs.serve, {})
vim.api.nvim_create_user_command("RockyDocsStop", mkdocs.stop_serve, {})
vim.api.nvim_create_user_command("RockyDocsBuild", mkdocs.build, {})
vim.api.nvim_create_user_command("RockyDocsStatus", mkdocs.mkdocs_status, {})

vim.api.nvim_create_user_command("PyVenvCreate", venv.create, {})
vim.api.nvim_create_user_command("PyVenvActivate", venv.activate, {})
vim.api.nvim_create_user_command("PyVenvDeactivate", venv.deactivate, {})
vim.api.nvim_create_user_command("PyVenvStatus", function()
	vim.notify(venv.status(), vim.log.levels.INFO)
end, {})
vim.api.nvim_create_user_command("PyVenvRemove", venv.remove, {})
