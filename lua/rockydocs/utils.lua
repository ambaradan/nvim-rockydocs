local M = {}

local config = require("rockydocs.configs").config
local state = require("rockydocs.configs").state

-- common utilities {{{

-- Function to activate the virtual environment for Mkdocs commands
function M.activate_venv()
	-- Check if the virtual environment is not active
	if not M.venv_is_active() then
		-- If not active, activate the virtual environment
		M.activate()
	end
end

-- Function to deactivate the virtual environment if active
function M.deactivate_venv()
	-- Check if the virtual environment is active
	if M.venv_is_active() then
		-- If active, deactivate the virtual environment
		M.deactivate()
	end
end

-- Check if MkDocs is installed in the current virtual environment
function M.mkdocs_is_installed()
	-- Check if the virtual environment is not active
	if not M.venv_is_active() then
		-- If not active, notify the user and return false
		vim.notify("No active virtual environment", vim.log.levels.WARN)
		return false
	end

	-- Get the path to the Python executable in the virtual environment
	local cmd = M.get_python_path() .. " -m pip show mkdocs"
	-- Run the command to check if MkDocs is installed
	local result = vim.fn.system(cmd)
	-- Check if the command was successful (exit code 0) and if the output contains "Name: mkdocs"
	return vim.v.shell_error == 0 and result:find("Name: mkdocs") ~= nil
end

-- Function to check if MkDocs is installed and notify the user
function M.check_mkdocs_installed()
	-- Check if MkDocs is installed in the current virtual environment
	if not M.mkdocs_is_installed() then
		-- If not installed, notify the user and return false
		vim.notify("MkDocs is not installed. Install MkDocs Environment first", vim.log.levels.ERROR)
		return false
	end
	-- If MkDocs is installed, return true
	return true
end

-- }}}

-- Utility functions {{{

-- Utility function to join paths with proper separators
local function path_join(...)
	return table.concat({ ... }, "/")
end

-- Get validated preserved paths (exists and is directory)
local function get_preserved_paths()
	-- Create an empty table to store valid paths
	local valid_paths = {}
	-- Iterate over the preserved paths in the config table
	for _, path in ipairs(config.preserved_paths) do
		-- Check if the path is a directory
		if vim.fn.isdirectory(path) == 1 then
			-- If the path is a directory, add it to the valid_paths table
			table.insert(valid_paths, path)
		end
	end
	-- Return the table of valid paths
	return valid_paths
end

-- Get the current project's virtual environment path
local function get_project_venv_path()
	-- Get the name of the current project directory
	local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
	-- Construct the path to the virtual environment directory
	return path_join(config.venvs_dir, project_name)
end

-- Ensure the venvs directory exists
local function ensure_venvs_dir()
	-- Check if the venvs directory exists
	if vim.fn.isdirectory(config.venvs_dir) == 0 then
		-- If the directory doesn't exist, create it with the "p" flag to create parent directories if needed
		vim.fn.mkdir(config.venvs_dir, "p")
	end
end

-- Check if virtual environment exists for current project
function M.venv_exists()
	-- Get the path to the current project's virtual environment
	local venv_path = get_project_venv_path()
	-- Check if the virtual environment directory exists
	return vim.fn.isdirectory(venv_path) == 1
end

-- Check if any virtual environment is active
function M.venv_is_active()
	-- Return the value of the active state variable
	return state.active
end

-- Get current Python executable path
function M.get_python_path()
	-- Use the Vim function exepath to get the path to the "python" executable
	return vim.fn.exepath("python")
end

-- }}}

-- Create a new virtual environment {{{

function M.create()
	-- Ensure that the directory for virtual environments exists
	ensure_venvs_dir()

	-- Get the path for the new virtual environment
	local venv_path = get_project_venv_path()

	-- Extract the virtual environment name from the path
	local venv_name = vim.fn.fnamemodify(venv_path, ":t")

	-- Check if a virtual environment already exists at the specified path
	if M.venv_exists() then
		-- If a virtual environment already exists, notify the user and return false
		vim.notify("Virtual environment already exists: " .. venv_name, vim.log.levels.WARN)
		return false
	end

	-- Construct the command to create a new virtual environment using the specified Python interpreter
	local cmd = string.format("python -m venv %s", vim.fn.shellescape(venv_path))

	-- Start a job to create the virtual environment and handle the exit event
	local job_id = vim.fn.jobstart(cmd, {
		on_exit = function(_, exit_code, _)
			-- Check the exit code to determine if the virtual environment creation was successful
			if exit_code ~= 0 then
				-- If the virtual environment creation failed, notify the user
				vim.notify("Failed to create virtual environment", vim.log.levels.ERROR)
			else
				-- If the virtual environment creation was successful, notify the user
				vim.notify("Created virtual environment: " .. venv_name, vim.log.levels.INFO)
			end
		end,
	})

	-- If job_id is less than or equal to 0, the job failed to start
	if job_id <= 0 then
		-- If the job failed to start, notify the user and return false
		vim.notify("Failed to start virtual environment creation job", vim.log.levels.ERROR)
		return false
	end

	-- Return true indicating that the job to create the virtual environment has been initiated
	return true
end

-- }}}

-- Activate virtual environment with Mason-aware PATH management {{{

function M.activate()
	-- Check if a virtual environment exists; if not, attempt to create one.
	-- If the creation fails, the function will return without further execution.
	if not M.venv_exists() and not M.create() then
		return
	end

	-- Check if a virtual environment is already active.
	if M.venv_is_active() then
		-- Compare the currently active virtual environment with the one to be activated.
		if vim.env.VIRTUAL_ENV == get_project_venv_path() then
			-- Extract the name of the currently active virtual environment.
			local venv_name = vim.fn.fnamemodify(vim.env.VIRTUAL_ENV, ":t")
			-- Notify the user that the virtual environment is already active.
			vim.notify(string.format("Virtual environment '%s' is already active", venv_name), vim.log.levels.WARN)
		else
			-- Extract the name of the currently active virtual environment.
			local active_venv_name = vim.fn.fnamemodify(vim.env.VIRTUAL_ENV, ":t")
			-- Notify the user that another virtual environment is already active.
			vim.notify(
				string.format("Another virtual environment is already active: '%s'", active_venv_name),
				vim.log.levels.WARN
			)
		end
		-- If a virtual environment is already active, return without further execution.
		return
	end

	-- Retrieve the path for the virtual environment.
	local venv_path = get_project_venv_path()
	-- Extract the name of the virtual environment from the path.
	local venv_name = vim.fn.fnamemodify(venv_path, ":t")

	-- Preserve existing paths to avoid losing them when modifying PATH.
	local preserved_paths = table.concat(get_preserved_paths(), ":")

	-- Set the VIRTUAL_ENV variable to point to the active virtual environment.
	vim.env.VIRTUAL_ENV = venv_path

	-- Update PATH to prioritize the virtual environment's bin directory.
	vim.env.PATH = path_join(venv_path, "bin") .. ":" .. preserved_paths .. ":" .. state.original_path

	-- Set the state to indicate that the virtual environment is active.
	state.active = true

	-- Notify the user that the virtual environment has been activated (name only).
	vim.notify(string.format("Activated virtual environment: '%s'", venv_name), vim.log.levels.INFO)
end

-- }}}

-- Deactivate virtual environment {{{

function M.deactivate()
	-- Check if a virtual environment is currently active
	if not M.venv_is_active() then
		-- If no virtual environment is active, notify the user with a warning message
		vim.notify("No virtual environment is active", vim.log.levels.WARN)
		return
	end

	-- Restore the original environment variables
	local preserved_paths = get_preserved_paths()
	-- Restore the original PATH including the preserved paths
	vim.env.PATH = table.concat(preserved_paths, ":") .. ":" .. state.original_path

	-- Clear the VIRTUAL_ENV variable to deactivate the virtual environment
	vim.env.VIRTUAL_ENV = nil
	-- Update the state to indicate that no virtual environment is active
	state.active = false

	-- Notify the user that the virtual environment has been deactivated
	vim.notify(
		string.format("Deactivated virtual environment\nRestored Python path: %s", M.get_python_path()),
		vim.log.levels.INFO
	)
end

-- }}}

-- Remove virtual environment {{{

function M.remove()
	-- Check if a virtual environment exists
	if not M.venv_exists() then
		-- Get the name of the virtual environment
		local venv_name = vim.fn.fnamemodify(get_project_venv_path(), ":t")
		-- Notify the user that no virtual environment was found
		vim.notify(string.format("No virtual environment '%s' found", venv_name), vim.log.levels.WARN)
		return false
	end

	-- Get the path of the virtual environment
	local venv_path = get_project_venv_path()
	-- Extract the name of the virtual environment from the path
	local venv_name = vim.fn.fnamemodify(venv_path, ":t")
	-- Build the command to remove the virtual environment
	local cmd = "rm -rf " .. vim.fn.shellescape(venv_path)
	-- Execute the removal command
	vim.fn.system(cmd)

	-- Check if the removal command was successful
	if vim.v.shell_error ~= 0 then
		-- Build an error message based on the shell error
		vim.notify(
			string.format("Failed to remove virtual environment '%s' (error code: %d)", venv_name, vim.v.shell_error),
			vim.log.levels.ERROR
		)
		return false
	end

	-- Notify the user that the virtual environment was removed successfully
	vim.notify(string.format("Removed virtual environment '%s'", venv_name), vim.log.levels.INFO)
	return true
end

-- }}}

-- Get status information {{{

function M.get_python_version(python_path)
	-- Check if a Python path was provided
	if not python_path or python_path == "" then
		-- If not, return a default message
		return "unknown version (no path)"
	end

	-- Execute the command to get the Python version
	local handle, err = io.popen(python_path .. " --version 2>&1")
	-- Check if the command was executed successfully
	if not handle then
		-- If not, return a default message with the error message
		return "unknown version (" .. (err or "failed to execute") .. ")"
	end

	-- Read the output of the command
	local result = handle:read("*a")
	-- Close the handle
	handle:close()

	-- Extract the version number from the output
	return result:match("Python (%d+%.%d+%.%d+)") or "unknown version (invalid output)"
end

function M.status()
	-- Initialize variables to store the Python path, name, and version
	local python_path, python_name, python_version
	local venv_name = ""

	-- Check if a virtual environment is currently active
	if M.venv_is_active() then
		-- Get the active virtual environment's Python path
		python_path = M.get_python_path()
		-- If the Python path is not found, return an error message
		if not python_path or python_path == "" then
			vim.notify("Active venv but Python path not found", vim.log.levels.WARN)
			return
		end

		-- Get the name of the active virtual environment
		if vim.env.VIRTUAL_ENV then
			venv_name = vim.fn.fnamemodify(vim.env.VIRTUAL_ENV, ":t") or "unnamed_venv"
		end

		-- Get the name and version of the Python interpreter in the active virtual environment
		python_name = vim.fn.fnamemodify(python_path, ":t") or "unknown_python"
		python_version = M.get_python_version(python_path)

		-- Display a formatted string with the active virtual environment and Python information
		local status_message = string.format(
			"Active: '%s'\nPython: %s (%s) [from virtual environment]",
			venv_name,
			python_name,
			python_version
		)
		vim.notify(status_message, vim.log.levels.INFO)

		-- Display additional information
		local additional_info =
			string.format("Python path: %s\nVirtual environment path: %s", python_path, vim.env.VIRTUAL_ENV)
		vim.notify(additional_info, vim.log.levels.INFO)

	-- Check if a virtual environment exists but is not currently active
	elseif M.venv_exists() then
		-- Get the original Python path (likely the system Python)
		python_path = state.original_python_path or ""
		-- Get the path of the project's virtual environment
		local project_venv_path = get_project_venv_path()

		-- Get the name of the project's virtual environment
		if project_venv_path then
			venv_name = vim.fn.fnamemodify(project_venv_path, ":t") or "unnamed_venv"
		end

		-- Get the name and version of the Python interpreter in the project's virtual environment
		python_name = vim.fn.fnamemodify(python_path, ":t") or "system_python"
		python_version = M.get_python_version(python_path)

		-- Display a formatted string with the inactive virtual environment and Python information
		local status_message = string.format(
			"Exists but inactive: '%s'\nPython: %s (%s) [from system]",
			venv_name,
			python_name,
			python_version
		)
		vim.notify(status_message, vim.log.levels.INFO)
	-- If no virtual environment exists at all
	else
		-- Get the original Python path (likely the system Python)
		python_path = state.original_python_path or ""
		-- Get the name of the system Python interpreter
		python_name = vim.fn.fnamemodify(python_path, ":t") or "system_python"
		-- Get the version of the system Python interpreter
		python_version = M.get_python_version(python_path)

		-- Display a formatted string with the information about the system Python
		local status_message =
			string.format("No virtual environment\nPython: %s (%s) [from system]", python_name, python_version)
		vim.notify(status_message, vim.log.levels.INFO)
	end
end

-- }}}

-- Open RockyDocs Environment in browser {{{

-- This function is responsible for opening the MkDocs browser.
function M.open_mkdocs_browser()
	-- Check if a server is running and we have a port
	if not state.current_server_port then
		-- If there is no server running, notify the user and return false
		vim.notify("No MkDocs server is currently running", vim.log.levels.WARN)
		return false
	end

	-- Construct the URL to open the MkDocs server
	local url = string.format("http://localhost:%d", state.current_server_port)

	-- Detect the operating system and choose the appropriate command to open the browser
	local open_cmd
	local os_command = vim.fn.system("uname -s"):gsub("\n", "")

	-- If the operating system is macOS, use the 'open' command
	if os_command == "Darwin" then
		open_cmd = string.format("open %s", url)
	-- If the operating system is Linux, try different browser commands
	elseif os_command == "Linux" then
		local browsers = {
			"xdg-open",
			"gnome-open",
			"kde-open",
			"x-www-browser",
			"firefox",
			"google-chrome",
			"chromium",
		}

		-- Try each browser command until one is found that is executable
		for _, browser in ipairs(browsers) do
			if vim.fn.executable(browser) == 1 then
				open_cmd = string.format("%s %s", browser, url)
				break
			end
		end
	-- If the operating system is Windows, use the 'start' command
	elseif os_command:match("MINGW") or os_command:match("MSYS") or os_command:match("Windows") then
		open_cmd = string.format("start %s", url)
	end

	-- Execute the command to open the browser
	if open_cmd then
		local result = vim.fn.system(open_cmd)
		if vim.v.shell_error ~= 0 then
			-- If the command failed, notify the user and return false
			vim.notify(string.format("Failed to open browser: %s", result), vim.log.levels.ERROR)
			return false
		else
			-- If the command succeeded, notify the user and return true
			vim.notify(string.format("Opening MkDocs at %s", url), vim.log.levels.INFO)
			return true
		end
	else
		-- If we couldn't determine a browser to open the URL, notify the user and return false
		vim.notify("Could not determine browser to open URL", vim.log.levels.ERROR)
		return false
	end
end

return M
