local M = {}

local utils = require("nvim-rockydocs.utils")
local configs = require("nvim-rockydocs.configs")

-- Install MkDocs for RockyDocs Project

function M.rockydocs()
	-- Check if the virtual environment is active
	if not utils.venv_is_active() then
		vim.notify("Please activate a virtual environment first", vim.log.levels.ERROR)
		return false
	end
	-- Clone the repository
	local clone_cmd = "git clone https://github.com/ambaradan/rockydocs-template.git ."
	vim.notify("Cloning repository...", vim.log.levels.INFO)
	local clone_result = vim.fn.system(clone_cmd)
	if vim.v.shell_error ~= 0 then
		vim.notify("Failed to clone repository: " .. clone_result, vim.log.levels.ERROR)
		return false
	else
		vim.notify("Successfully cloned repository", vim.log.levels.INFO)
		-- Install requirements
		local pip_cmd = utils.get_python_path() .. " -m pip install -r requirements.txt"
		vim.notify("Installing requirements...", vim.log.levels.INFO)
		local install_result = vim.fn.system(pip_cmd)
		if vim.v.shell_error ~= 0 then
			vim.notify("Failed to install requirements: " .. install_result, vim.log.levels.ERROR)
			return false
		else
			vim.notify("Successfully installed requirements", vim.log.levels.INFO)
			-- Remove requirements.txt, README.md files, and .git folder silently
			local files = { "requirements.txt", "README.md", "LICENSE" }
			local folders = { ".git" }

			-- Remove files
			for _, file in ipairs(files) do
				local f = io.open(file, "r")
				if f then
					f:close()
					os.remove(file)
				end
			end

			-- Remove folders
			for _, folder in ipairs(folders) do
				local command = "rm -rf " .. folder
				os.execute(command)
			end
			vim.notify("RockyDocs Enviroment Installed", vim.log.levels.INFO)
			return true
		end
	end
end

-- Serve the MkDocs documentation {{{

function M.serve()
	utils.activate_venv() -- Activate the virtual environment
	if not utils.venv_is_active() then -- Check if the virtual environment is now active
		vim.notify("Please activate a virtual environment first", vim.log.levels.ERROR)
		return false
	end

	utils.check_mkdocs_installed()

	if vim.fn.filereadable("mkdocs.yml") ~= 1 then -- Ensure mkdocs.yml is present
		vim.notify("No mkdocs.yml found in the current directory", vim.log.levels.ERROR)
		return false
	end

	-- Stop any existing server first if already running
	if configs.server_job_id and vim.fn.jobwait({ configs.server_job_id }, 0)[1] == -1 then
		vim.fn.jobstop(configs.server_job_id)
	end

	local cmd = utils.get_python_path() .. " -m mkdocs serve -q"
	vim.notify("Starting RockyDocs server...", vim.log.levels.INFO)

	-- Start the server as a background job
	configs.server_job_id = vim.fn.jobstart(cmd, {
		on_stdout = function(_, data)
			if data then
				for _, line in ipairs(data) do
					if line:find("Serving") then
						vim.notify(line, vim.log.levels.INFO)
					end
				end
			end
		end,
		on_stderr = function(_, data)
			if data then
				vim.notify(table.concat(data, "\n"), vim.log.levels.INFO)
			end
		end,
		on_exit = function()
			utils.deactivate_venv()
			configs.server_job_id = nil
		end,
	})

	return true
end

-- }}}

-- Stop the running MkDocs server {{{

function M.stop_serve()
	if not configs.server_job_id then
		vim.notify("No RockyDocs server is currently running", vim.log.levels.WARN)
		return false
	end

	-- Check if the job is still running
	if vim.fn.jobwait({ configs.server_job_id }, 0)[1] == -1 then
		vim.fn.jobstop(configs.server_job_id)
		vim.notify("Stopped RockyDocs server", vim.log.levels.INFO)
		configs.server_job_id = nil
		utils.deactivate_venv() -- Automatically deactivate the virtual environment after stopping
		return true
	else
		vim.notify("RockyDocs server is not running", vim.log.levels.WARN)
		configs.server_job_id = nil
		return false
	end
end

-- }}}

-- Build the MkDocs documentation {{{

function M.build()
	utils.activate_venv()
	if not utils.venv_is_active() then
		vim.notify("Please activate a virtual environment first", vim.log.levels.ERROR)
		return false
	end

	if not utils.mkdocs_is_installed() then
		vim.notify("RockyDocs is not installed. Install enviroment first", vim.log.levels.ERROR)
		return false
	end

	if vim.fn.filereadable("mkdocs.yml") ~= 1 then
		vim.notify("No mkdocs.yml found in current directory", vim.log.levels.ERROR)
		return false
	end

	local cmd = utils.get_python_path() .. " -m mkdocs build"
	vim.notify("Building RockyDocs documentation...", vim.log.levels.INFO)

	vim.fn.system(cmd)
	if vim.v.shell_error ~= 0 then
		vim.notify("Failed to build documentation", vim.log.levels.ERROR)
		return false
	else
		vim.notify("Successfully built documentation in site/ directory", vim.log.levels.INFO)
		return true
	end
end

-- }}}

-- Show the status of MkDocs and its environment {{{

function M.mkdocs_status()
	local status = "RockyDocs status:\n"

	if not utils.venv_is_active() then
		if utils.venv_exists() then
			status = status .. "Virtual environment exists but is not active\n"
		else
			status = status .. "No active virtual environment and no virtual environment exists\n"
		end
	else
		status = status .. "Virtual environment: " .. vim.env.VIRTUAL_ENV .. "\n"
		status = status .. "MkDocs installed: " .. (utils.mkdocs_is_installed() and "Yes" or "No") .. "\n"

		if vim.fn.filereadable("mkdocs.yml") == 1 then
			status = status .. "RockyDocs project detected in current directory\n"
		else
			status = status .. "No RockyDocs project in current directory\n"
		end
	end

	if configs.server_job_id and vim.fn.jobwait({ configs.server_job_id }, 0)[1] == -1 then
		status = status .. "MkDocs server: Running\n"
	else
		status = status .. "MkDocs server: Not running\n"
	end

	vim.notify(status, vim.log.levels.INFO)
end

-- }}}

return M
