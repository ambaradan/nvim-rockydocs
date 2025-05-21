--[[
    main.lua - Core Module for RockyDocs Documentation System

    Primary Functions:
    1. rockydocs()       - Full project setup (env validation, repo cloning, dependency install)
    2. serve()           - Starts MkDocs development server with port management
    3. stop_serve()      - Gracefully terminates running MkDocs server
    4. build()           - Executes documentation build process with real-time output
    5. mkdocs_status()   - Provides system status (venv, MkDocs, server state)

    Features:
    - Interactive buffer-based output for setup/build processes
    - Automatic virtual environment handling
    - Port range validation and conflict resolution
    - Visual notifications with error levels
    - Job management for async operations

    Dependencies:
    - Requires rockydocs.utils for environment utilities
    - Requires rockydocs.configs for system configuration

    License:
    Distributed under the MIT License.
    Full text at: https://opensource.org/licenses/MIT
]]

local M = {}

local utils = require("rockydocs.utils")
local configs = require("rockydocs.configs")
local state = require("rockydocs.configs").state

-- Install MkDocs for RockyDocs Project {{{

---@desc Main setup function for RockyDocs documentation system.
---Handles environment setup, template cloning, and dependency installation.
---@return boolean # `true` if successful, `false` if failed
function M.rockydocs()
	-- Check if the virtual environment is active
	if not utils.venv_is_active() then
		vim.notify("Please activate a virtual environment first", vim.log.levels.ERROR)
		return false
	end

	local initial_lines = {
		"Starting RockyDocs setup...",
		"----------------------------------",
		"",
	}

	-- Create buffer with right-aligned positioning
	local buf, win = utils.create_output_buffer("RockyDocs Setup", 0.35, 0.6, initial_lines, {
		right = true,
		wrap = true,
	})

	-- Rest of the existing implementation remains the same
	local lines = initial_lines
	-- Appends new lines to the output buffer
	local function append_to_buffer(new_lines)
		if type(new_lines) == "string" then
			new_lines = { new_lines }
		end

		for _, line in ipairs(new_lines) do
			if line ~= "" then
				table.insert(lines, line)
			end
		end

		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		vim.api.nvim_win_set_cursor(win, { #lines, 0 })
	end

	append_to_buffer({ " Cloning repository...", " " })

	-- Create a temporary directory
	local tmp_dir = vim.fn.tempname()
	vim.fn.mkdir(tmp_dir)

	-- Clones the RockyDocs template repository into the temporary directory
	append_to_buffer("Cloning into temporary directory...")
	vim.fn.jobstart("git clone https://github.com/ambaradan/rockydocs-template.git " .. tmp_dir, {
		on_stdout = function(_, data)
			append_to_buffer(data)
		end,
		on_stderr = function(_, data)
			append_to_buffer(data)
		end,
		on_exit = function(_, exit_code)
			if exit_code ~= 0 then
				append_to_buffer({
					"✖ Failed to clone repository",
					"Exit code: " .. tostring(exit_code),
				})
				vim.notify("Failed to clone repository", vim.log.levels.ERROR)
				-- Add close button hint
				append_to_buffer(" ")
				append_to_buffer("Press 'q' to close this window")
				vim.api.nvim_buf_set_keymap(buf, "n", "q", ":q<CR>", { noremap = true, silent = true })
				vim.api.nvim_buf_set_keymap(buf, "n", "<ESC>", ":q<CR>", { noremap = true, silent = true })
				-- Remove the temporary directory
				vim.fn.jobstart("rm -rf " .. tmp_dir, { detach = true })
				return
			end

			append_to_buffer({
				"✔ Successfully cloned repository",
				" ",
				" Copying files...",
				" ",
			})

			-- Copy necessary files from the temporary directory
			local files = {
				"docs",
				".theme",
				"mkdocs.yml",
			}

			for _, file in ipairs(files) do
				local src = tmp_dir .. "/" .. file
				local dst = vim.fn.getcwd() .. "/" .. file

				-- Check if the file or directory already exists in the working folder
				local exists = false
				local handle = io.open(file, "r")
				if handle then
					io.close(handle)
					exists = true
				end

				if not exists then
					-- If the file or directory does not exist, copy it
					if vim.fn.filereadable(src) == 1 then
						-- If the source is a file, copy it
						append_to_buffer(string.format("Copying file: %s", file))
						vim.fn.jobstart("cp " .. src .. " " .. dst, { detach = true })
						append_to_buffer(string.format("File copied successfully: %s", file))
					elseif vim.fn.isdirectory(src) == 1 then
						-- If the source is a directory, copy it recursively
						append_to_buffer(string.format("Copying directory: %s", file))
						vim.fn.jobstart("cp -r " .. src .. " " .. dst, { detach = true })
						append_to_buffer(string.format("Directory copied successfully: %s", file))
					end
				else
					append_to_buffer(string.format("Skipping %s: already exists", file))
				end
			end
			append_to_buffer("File copy operation complete")

			-- Remove the temporary directory
			vim.fn.jobstart("rm -rf " .. tmp_dir, { detach = true })

			append_to_buffer({
				"✔ Successfully copied files",
				" ",
				" Installing requirements...",
			})

			-- Installs Python dependencies from requirements.txt
			local pip_cmd = utils.get_python_path()
				.. " -m pip install -r https://raw.githubusercontent.com/ambaradan/rockydocs-template/master/requirements.txt --quiet --disable-pip-version-check"

			vim.fn.jobstart(pip_cmd, {
				on_stdout = function(_, data)
					append_to_buffer(data)
				end,
				on_stderr = function(_, data)
					append_to_buffer(data)
				end,
				on_exit = function(_, pip_exit_code)
					if pip_exit_code ~= 0 then
						append_to_buffer({
							" ",
							"✖ Failed to install requirements",
							"Exit code: " .. tostring(pip_exit_code),
						})
						vim.notify("Failed to install requirements", vim.log.levels.ERROR)
					else
						append_to_buffer({
							"✔ Successfully installed requirements",
							" ",
							" RockyDocs environment ready!",
							" ",
							" :RockydocsServe to run it",
						})
						vim.notify("RockyDocs setup completed", vim.log.levels.INFO)
					end

					-- Add close button hint
					append_to_buffer(" ")
					append_to_buffer("Press 'q' to close this window")
				end,
				cwd = vim.fn.getcwd(),
			})
		end,
		cwd = vim.fn.getcwd(),
	})

	return true
end

-- }}}

-- Serve the MkDocs documentation {{{

--- @desc Serve the MkDocs documentation site
--- Starts a local development server for the MkDocs documentation.
--- Requires an active virtual environment with MkDocs installed.
--- Automatically handles port selection and stops any existing server.
--- @param opts table|nil Optional configuration table with these possible fields:
---   - port (number|nil): The port number to use for the server. If not provided, uses the default port from config.
--- @return boolean # Returns true if server started successfully, false otherwise
function M.serve(opts)
	-- Show basic environment status
	local status_msg = utils.status()
	vim.notify("Environment Status:\n" .. status_msg, vim.log.levels.INFO)

	if not utils.venv_is_active() then
		vim.notify("Please activate a virtual environment first", vim.log.levels.ERROR)
		return false
	end

	if not utils.check_mkdocs_installed() then
		return false
	end

	if vim.fn.filereadable("mkdocs.yml") ~= 1 then
		vim.notify("No mkdocs.yml found in the current directory", vim.log.levels.ERROR)
		return false
	end

	-- Stop any existing server first
	if configs.server_job_id and vim.fn.jobwait({ configs.server_job_id }, 0)[1] == -1 then
		vim.fn.jobstop(configs.server_job_id)
	end

	-- Determine port
	local port = opts and opts.port or configs.config.mkdocs_server.default_port

	-- Validate port range
	if port < configs.config.mkdocs_server.port_range_start or port > configs.config.mkdocs_server.port_range_end then
		vim.notify("Port out of allowed range. Using default port.", vim.log.levels.WARN)
		port = configs.config.mkdocs_server.default_port
	end

	local python_path = utils.get_python_path()
	local cmd = string.format("%s -m mkdocs serve -q -a localhost:%d", python_path, port)

	vim.notify(string.format("Starting RockyDocs server on port %d...", port), vim.log.levels.INFO)

	-- Start server
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
			configs.state.current_server_port = nil
		end,
	})

	configs.state.current_server_port = port
	return true
end

-- }}}

-- Stop the running MkDocs server {{{

--- @desc Stop the running MkDocs documentation server
--- Checks for and stops any currently running RockyDocs server.
--- Automatically cleans up server state and deactivates the virtual environment.
--- @return boolean # Returns true if server was stopped successfully, false otherwise
function M.stop_serve()
	-- Early return if no server job ID is registered
	if not configs.server_job_id then
		vim.notify("No RockyDocs server is currently running", vim.log.levels.WARN)
		return false
	end

	-- Store the job ID locally before clean up
	local job_id = configs.server_job_id
	configs.server_job_id = nil
	configs.state.current_server_port = nil

	-- Check job status and stop if running
	local job_status = vim.fn.jobwait({ job_id }, 0)[1]

	if job_status == -1 then -- Job is still running
		local success = pcall(vim.fn.jobstop, job_id)

		if success then
			vim.notify("Stopped RockyDocs server", vim.log.levels.INFO)
			-- Only deactivate venv if it was activated for this server
			if utils.venv_is_active() then
				utils.deactivate_venv()
			end
			return true
		else
			vim.notify("Failed to stop RockyDocs server", vim.log.levels.ERROR)
			return false
		end
	else
		-- Job is already finished or failed
		vim.notify("RockyDocs server is not running", vim.log.levels.INFO)
		-- Clean up venv if it was left active
		if utils.venv_is_active() then
			utils.deactivate_venv()
		end
		return false
	end
end

-- }}}

-- Build the MkDocs documentation {{{

---@desc Main build function for RockyDocs documentation system.
---Handles environment checks, configuration validation, and executes MkDocs build.
---@return boolean # Returns `true` if build started successfully, `false` on failure
function M.build()
	-- Activate the virtual environment first
	utils.activate_venv()

	if not utils.venv_is_active() then
		vim.notify(
			"Build failed: No active virtual environment found\nPlease run ':RockyDocsActivate' first",
			vim.log.levels.ERROR
		)
		return false
	end

	local status_lines = {
		"Starting RockyDocs build process...",
		"----------------------------------",
		"",
	}

	-- Create buffer with centered positioning and no wrapping
	local buf, win = utils.create_output_buffer("RockyDocs Status", 0.35, 0.6, status_lines, {
		right = true,
		bottom = true,
		wrap = true,
	})

	-- Get Python path and build command
	local python_path = utils.get_python_path()
	local cmd = python_path .. " -m mkdocs build"

	-- Start the build job
	local job_id = vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		on_stdout = function(_, data, _)
			if data then
				-- Append output to buffer
				local current_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
				for _, line in ipairs(data) do
					if line ~= "" then
						table.insert(current_lines, line)
					end
				end
				vim.api.nvim_buf_set_lines(buf, 0, -1, false, current_lines)
				-- Auto-scroll to bottom
				vim.api.nvim_win_set_cursor(win, { #current_lines, 0 })
			end
		end,
		on_stderr = function(_, data, _)
			if data then
				-- Append error output to buffer
				local current_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
				for _, line in ipairs(data) do
					if line ~= "" then
						table.insert(current_lines, "❗ " .. line)
					end
				end
				vim.api.nvim_buf_set_lines(buf, 0, -1, false, current_lines)
				-- Auto-scroll to bottom
				vim.api.nvim_win_set_cursor(win, { #current_lines, 0 })
			end
		end,
		on_exit = function(_, exit_code, _)
			local current_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
			if exit_code == 0 then
				table.insert(current_lines, "")
				table.insert(current_lines, "✔  Build completed successfully!")
				table.insert(current_lines, "Output generated in the 'site/' directory")
			else
				table.insert(current_lines, "")
				table.insert(current_lines, "✖  Build failed with exit code " .. exit_code)
				table.insert(current_lines, "Check the output above for errors")
			end
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, current_lines)

			-- Add close button hint
			table.insert(current_lines, "")
			table.insert(current_lines, "Press 'q' to close this window")
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, current_lines)
			-- Auto-scroll to bottom
			vim.api.nvim_win_set_cursor(win, { #current_lines, 0 })
		end,
	})

	return job_id > 0 -- Return true if job started successfully
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
		status = status .. "Virtual environment: " .. vim.fn.fnamemodify(vim.env.VIRTUAL_ENV, ":t") .. "\n"
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

-- Open RockyDocs Environment in browser {{{

-- This function is responsible for opening the MkDocs browser.
function M.open_browser()
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

-- }}}

return M
