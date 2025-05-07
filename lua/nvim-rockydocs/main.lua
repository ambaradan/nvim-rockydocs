local M = {}

local utils = require("nvim-rockydocs.utils")
local configs = require("nvim-rockydocs.configs")

-- Install MkDocs for RockyDocs Project {{{

--- @desc Creates a new RockyDocs project by downloading the latest release.
--- This function assumes that a virtual environment is already activated.
--- If no virtual environment is active, it will notify the user to activate one first.
--- It also removes unnecessary files and folders after downloading.
function M.rockydocs()
	-- Check if the virtual environment is active
	if not utils.venv_is_active() then
		vim.notify("Please activate a virtual environment first", vim.log.levels.ERROR)
		return false
	end

	-- Get the path to the Python executable
	local python_path = utils.get_python_path()

	-- Download the latest release
	local download_cmd = [[
        curl -L -o rockydocs.zip https://github.com/ambaradan/rockydocs-template/archive/refs/heads/main.zip &&
        unzip rockydocs.zip &&
        rm rockydocs.zip
    ]]
	local download_job = vim.fn.jobstart(download_cmd, {
		on_stdout = function(_, data)
			for _, line in ipairs(data) do
				vim.notify(line, vim.log.levels.INFO)
			end
		end,
		on_stderr = function(_, data)
			for _, line in ipairs(data) do
				vim.notify(line, vim.log.levels.ERROR)
			end
		end,
	})

	-- Wait for the download job to finish
	local download_status = vim.fn.jobwait({ download_job })
	if download_status[1] == 0 then
		vim.notify("Latest release downloaded successfully", vim.log.levels.INFO)
	elseif download_status[1] == -1 then
		vim.notify("Download job is still running", vim.log.levels.WARN)
	else
		vim.notify("Download job has failed with status " .. tostring(download_status[1]), vim.log.levels.ERROR)
	end

	-- Move files from the extracted directory to the current directory
	local move_files_cmd = [[
        mv rockydocs-template-main/* . &&
        mv rockydocs-template-main/.* . &&
        rm -rf rockydocs-template-main
    ]]
	local move_files_job = vim.fn.jobstart(move_files_cmd, {
		on_stdout = function(_, data)
			for _, line in ipairs(data) do
				vim.notify(line, vim.log.levels.INFO)
			end
		end,
		on_stderr = function(_, data)
			for _, line in ipairs(data) do
				vim.notify(line, vim.log.levels.ERROR)
			end
		end,
	})

	-- Wait for the move job to finish
	vim.fn.jobwait({ move_files_job })

	-- Check if pip is up to date
	local pip_upgrade_cmd = string.format("%s -m pip install --upgrade pip", python_path)
	local pip_upgrade_job = vim.fn.jobstart(pip_upgrade_cmd, {
		on_stdout = function(_, data)
			for _, line in ipairs(data) do
				vim.notify(line, vim.log.levels.INFO)
			end
		end,
		on_stderr = function(_, data)
			for _, line in ipairs(data) do
				vim.notify(line, vim.log.levels.ERROR)
			end
		end,
	})

	-- Wait for the pip upgrade job to finish
	local pip_upgrade_status = vim.fn.jobwait({ pip_upgrade_job })
	if pip_upgrade_status[1] ~= -1 then
		if pip_upgrade_status[1] == 0 then
			vim.notify("pip upgraded successfully", vim.log.levels.INFO)
		else
			vim.notify("Failed to upgrade pip", vim.log.levels.ERROR)
			return
		end
	end

	-- Install requirements
	local install_cmd = python_path .. " -m pip install --quiet -r requirements.txt"
	local install_job = vim.fn.jobstart(install_cmd, {
		on_stdout = function(_, data)
			for _, line in ipairs(data) do
				vim.notify(line, vim.log.levels.INFO)
			end
		end,
		on_stderr = function(_, data)
			for _, line in ipairs(data) do
				vim.notify(line, vim.log.levels.ERROR)
			end
		end,
	})

	-- Wait for the install job to finish
	vim.fn.jobwait({ install_job })

	-- Remove unnecessary files and folders, preserving the .theme folder
	local files_to_remove = { "rockydocs-template-main", "requirements.txt", "README.md", "LICENSE", ".git" }
	for _, file in ipairs(files_to_remove) do
		if vim.fn.filereadable(file) == 1 then
			vim.notify(string.format("Removing file: %s", file), vim.log.levels.INFO)
			os.remove(file)
		elseif vim.fn.isdirectory(file) == 1 and file ~= ".theme" then
			vim.notify(string.format("Removing directory: %s", file), vim.log.levels.INFO)
			vim.fn.system(string.format("rm -rf %s", file))
		end
	end

	vim.notify("RockyDocs project setup complete", vim.log.levels.INFO)

	return true
end

-- }}}

-- Serve the MkDocs documentation {{{

--- @desc Starts the MkDocs server to serve the documentation.
--- This function will:
--- 1. Activate the virtual environment if not already active.
--- 2. Check if MkDocs is installed in the virtual environment.
--- 3. Ensure that an `mkdocs.yml` file is present in the current directory.
--- 4. Stop any existing MkDocs server if it's already running.
--- 5. Determine the port to use based on the provided options or default configuration.
--- 6. Start the MkDocs server using the specified port.
--- @param opts table Optional parameters, including the port number to use.
function M.serve(opts)
	-- Activate the virtual environment
	utils.activate_venv()

	-- Check if the virtual environment is now active
	if not utils.venv_is_active() then
		vim.notify("Please activate a virtual environment first", vim.log.levels.ERROR)
		return false
	end

	-- Check if MkDocs is installed
	utils.check_mkdocs_installed()

	-- Ensure mkdocs.yml is present
	if vim.fn.filereadable("mkdocs.yml") ~= 1 then
		vim.notify("No mkdocs.yml found in the current directory", vim.log.levels.ERROR)
		return false
	end

	-- Stop any existing server first if already running
	if configs.server_job_id and vim.fn.jobwait({ configs.server_job_id }, 0)[1] == -1 then
		vim.fn.jobstop(configs.server_job_id)
	end

	-- Determine the port to use
	local port = opts and opts.port or configs.config.mkdocs_server.default_port

	-- Check if port is within the allowed range
	if port < configs.config.mkdocs_server.port_range_start or port > configs.config.mkdocs_server.port_range_end then
		vim.notify("Port out of allowed range. Using default port.", vim.log.levels.WARN)
		port = configs.config.mkdocs_server.default_port
	end

	-- Construct the command to start the MkDocs server
	local cmd = string.format("%s -m mkdocs serve -a localhost:%d -q", utils.get_python_path(), port)

	-- Notify the user that the server is starting
	vim.notify(string.format("Starting RockyDocs server on port %d...", port), vim.log.levels.INFO)

	-- Start the server as a background job
	configs.server_job_id = vim.fn.jobstart(cmd, {
		-- Handle stdout output from the job
		on_stdout = function(_, data)
			if data then
				for _, line in ipairs(data) do
					if line:find("Serving") then
						vim.notify(line, vim.log.levels.INFO)
					end
				end
			end
		end,

		-- Handle stderr output from the job
		on_stderr = function(_, data)
			if data then
				vim.notify(table.concat(data, "\n"), vim.log.levels.INFO)
			end
		end,

		-- Handle job exit event
		on_exit = function()
			-- Deactivate the virtual environment when the job exits
			utils.deactivate_venv()
			configs.server_job_id = nil
			configs.state.current_server_port = nil
		end,
	})

	-- Store the current server port
	configs.state.current_server_port = port

	return true
end

-- }}}

-- Stop the running MkDocs server {{{

--- @desc Stops the currently running MkDocs server.
--- This function will:
--- 1. Check if a MkDocs server is currently running.
--- 2. If a server is running, it will stop the job and notify the user.
--- 3. If no server is running, it will notify the user accordingly.
--- @return boolean True if the server was successfully stopped, false otherwise.
function M.stop_serve()
	-- Check if a MkDocs server is currently running
	if not configs.server_job_id then
		vim.notify("No RockyDocs server is currently running", vim.log.levels.WARN)
		return false
	end

	-- Check if the job is still running
	if vim.fn.jobwait({ configs.server_job_id }, 0)[1] == -1 then
		-- Stop the job
		vim.fn.jobstop(configs.server_job_id)

		-- Notify the user that the server has been stopped
		vim.notify("Stopped RockyDocs server", vim.log.levels.INFO)

		-- Reset the server job ID and current server port
		configs.server_job_id = nil

		-- Automatically deactivate the virtual environment after stopping
		utils.deactivate_venv()

		return true
	else
		-- If the job is not running, notify the user and reset the server job ID
		vim.notify("RockyDocs server is not running", vim.log.levels.WARN)
		configs.server_job_id = nil

		return false
	end
end

-- }}}

-- Build the MkDocs documentation {{{

--- @desc Builds the MkDocs documentation for the current project.
--- This function will:
--- 1. Activate the virtual environment if not already active.
--- 2. Check if MkDocs is installed in the virtual environment.
--- 3. Ensure that an `mkdocs.yml` file is present in the current directory.
--- 4. Build the documentation using the `mkdocs build` command.
--- @return boolean True if the documentation was successfully built, false otherwise.
function M.build()
	-- Activate the virtual environment
	utils.activate_venv()

	-- Check if the virtual environment is now active
	if not utils.venv_is_active() then
		vim.notify("Please activate a virtual environment first", vim.log.levels.ERROR)
		return false
	end

	-- Check if MkDocs is installed
	if not utils.mkdocs_is_installed() then
		vim.notify("RockyDocs is not installed. Install environment first", vim.log.levels.ERROR)
		return false
	end

	-- Ensure mkdocs.yml is present
	if vim.fn.filereadable("mkdocs.yml") ~= 1 then
		vim.notify("No mkdocs.yml found in current directory", vim.log.levels.ERROR)
		return false
	end

	-- Build the documentation
	local cmd = utils.get_python_path() .. " -m mkdocs build"
	vim.notify("Building RockyDocs documentation...", vim.log.levels.INFO)

	-- Execute the build command
	local result = vim.fn.system(cmd)

	-- Check if the build was successful
	if vim.v.shell_error ~= 0 then
		vim.notify("Failed to build documentation", vim.log.levels.ERROR)
		return false
	else
		vim.notify("Successfully built documentation in site/ directory", vim.log.levels.INFO)
		return true
	end
end

--- Example usage:

-- }}}

-- Show the status of MkDocs and its environment {{{

--- @desc Displays the status of the MkDocs environment and server.
--- This function will:
--- 1. Check if a virtual environment is active or exists.
--- 2. Check if MkDocs is installed in the virtual environment.
--- 3. Check if an `mkdocs.yml` file is present in the current directory.
--- 4. Check if the MkDocs server is running.
--- 5. Display a formatted status message with the above information.
function M.mkdocs_status()
	-- Initialize the status message
	local status = "RockyDocs status:\n"

	-- Check if a virtual environment is active
	if not utils.venv_is_active() then
		-- If no virtual environment is active, check if one exists
		if utils.venv_exists() then
			status = status .. "Virtual environment exists but is not active\n"
		else
			status = status .. "No active virtual environment and no virtual environment exists\n"
		end
	else
		-- If a virtual environment is active, display its name
		local venv_path = vim.env.VIRTUAL_ENV
		local venv_name = vim.fn.fnamemodify(venv_path, ":t")
		status = status .. "Virtual environment: " .. venv_name .. "\n"

		-- MkDocs installation status
		status = status .. "MkDocs installed: " .. (utils.mkdocs_is_installed() and "Yes" or "No") .. "\n"

		-- Check if an mkdocs.yml file is present
		if vim.fn.filereadable("mkdocs.yml") == 1 then
			status = status .. "RockyDocs project detected in current directory\n"
		else
			status = status .. "No RockyDocs project in current directory\n"
		end
	end

	-- Check if the MkDocs server is running
	if configs.server_job_id and vim.fn.jobwait({ configs.server_job_id }, 0)[1] == -1 then
		status = status .. "MkDocs server: Running\n"
	else
		status = status .. "MkDocs server: Not running\n"
	end

	-- Display the formatted status message
	vim.notify(status, vim.log.levels.INFO)
end

-- }}}

return M
