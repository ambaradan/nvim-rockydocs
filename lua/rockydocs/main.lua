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

	-- Create a new buffer for setup output
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(buf, "RockyDocs Setup")
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
	vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })

	-- Calculate dimensions for floating window (80% of editor size)
	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	-- Create floating window
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = "RockyDocs Setup",
		title_pos = "center",
	})

	-- Set window options
	vim.api.nvim_set_option_value("number", false, { scope = "local", win = win })
	vim.api.nvim_set_option_value("relativenumber", false, { scope = "local", win = win })
	vim.api.nvim_set_option_value("wrap", false, { scope = "local", win = win })

	local lines = { "🚀 Starting RockyDocs setup...", "----------------------------------", "" }
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

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

	append_to_buffer("Cloning repository...")

	-- Clones the RockyDocs template repository
	vim.fn.jobstart("git clone https://github.com/ambaradan/rockydocs-template.git .", {
		on_stdout = function(_, data)
			append_to_buffer(data)
		end,
		on_stderr = function(_, data)
			append_to_buffer(data)
		end,
		on_exit = function(_, exit_code)
			if exit_code ~= 0 then
				append_to_buffer({
					" ",
					"✖ Failed to clone repository",
					"Exit code: " .. tostring(exit_code),
				})
				vim.notify("Failed to clone repository", vim.log.levels.ERROR)
				-- Add close button hint
				append_to_buffer(" ")
				append_to_buffer("Press 'q' to close this window")
				vim.api.nvim_buf_set_keymap(buf, "n", "q", ":q<CR>", { noremap = true, silent = true })
				vim.api.nvim_buf_set_keymap(buf, "n", "<ESC>", ":q<CR>", { noremap = true, silent = true })
				return
			end

			append_to_buffer({
				" ",
				"✔ Successfully cloned repository",
				" ",
				" Installing requirements...",
				" ",
			})

			-- Installs Python dependencies from requirements.txt
			local pip_cmd = utils.get_python_path() .. " -m pip install -r requirements.txt --disable-pip-version-check"

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
							" ",
							"✔ Successfully installed requirements",
							" ",
							" RockyDocs environment ready!",
							" ",
							" :RockydocsServe to run it",
						})
						vim.notify("RockyDocs setup completed", vim.log.levels.INFO)
					end

					-- Cleans up temporary files after setup
					local files = { "requirements.txt", "README.md", "LICENSE", ".git" }
					for _, file in ipairs(files) do
						if vim.fn.filereadable(file) == 1 then
							os.remove(file)
						elseif vim.fn.isdirectory(file) == 1 then
							vim.fn.jobstart("rm -rf " .. file, { detach = true })
						end
					end

					-- Add close button hint
					append_to_buffer(" ")
					append_to_buffer("Press 'q' to close this window")
					vim.api.nvim_buf_set_keymap(buf, "n", "q", ":q<CR>", { noremap = true, silent = true })
					vim.api.nvim_buf_set_keymap(buf, "n", "<ESC>", ":q<CR>", { noremap = true, silent = true })
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

	if not utils.mkdocs_is_installed() then
		vim.notify(
			"Build failed: MkDocs is not installed in the current virtual environment\n"
				.. "Please run ':RockyDocsInstall' to set up the documentation environment",
			vim.log.levels.ERROR
		)
		return false
	end

	if vim.fn.filereadable("mkdocs.yml") ~= 1 then
		vim.notify(
			"Build failed: No mkdocs.yml configuration file found in the current directory\n"
				.. "This file is required to build your documentation",
			vim.log.levels.ERROR
		)
		return false
	end

	-- Create a new buffer for build output
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(buf, "RockyDocs Build Output")
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
	vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })

	-- Calculate dimensions for floating window (80% of editor size)
	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	-- Create floating window
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = "RockyDocs Build",
		title_pos = "center",
	})

	-- Set window options
	vim.api.nvim_set_option_value("number", false, { scope = "local", win = win })
	vim.api.nvim_set_option_value("relativenumber", false, { scope = "local", win = win })
	vim.api.nvim_set_option_value("wrap", false, { scope = "local", win = win })

	-- Add initial content to the buffer
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
		"🚀 Starting RockyDocs build process...",
		"----------------------------------",
		"",
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
			-- Set keymap to close window
			vim.api.nvim_buf_set_keymap(buf, "n", "q", ":q<CR>", { noremap = true, silent = true })
			vim.api.nvim_buf_set_keymap(buf, "n", "<ESC>", ":q<CR>", { noremap = true, silent = true })
		end,
	})

	return job_id > 0 -- Return true if job started successfully
end

-- }}}

-- Show the status of MkDocs and its environment {{{

--- @desc Get comprehensive status of RockyDocs environment
--- Reports on virtual environment status, MkDocs installation, project detection, and server status
--- @return nil
function M.mkdocs_status()
	local status_lines = { "RockyDocs status:" }

	-- Virtual environment status
	if utils.venv_is_active() then
		table.insert(
			status_lines,
			string.format(
				"Virtual environment: %s",
				vim.env.VIRTUAL_ENV and vim.fn.fnamemodify(vim.env.VIRTUAL_ENV, ":t") or "None"
			)
		)
		table.insert(status_lines, string.format("MkDocs installed: %s", utils.mkdocs_is_installed() and "Yes" or "No"))
		table.insert(
			status_lines,
			string.format(
				"Project: %s",
				vim.fn.filereadable("mkdocs.yml") == 1 and "RockyDocs project detected" or "No project detected"
			)
		)
	else
		table.insert(
			status_lines,
			utils.venv_exists() and "Virtual environment exists but is not active" or "No virtual environment exists"
		)
	end

	-- Server status
	local server_running = configs.server_job_id and vim.fn.jobwait({ configs.server_job_id }, 0)[1] == -1
	table.insert(status_lines, string.format("MkDocs server: %s", server_running and "Running" or "Not running"))

	if server_running and configs.state.current_server_port then
		table.insert(status_lines, string.format("Server port: %d", configs.state.current_server_port))
	end

	vim.notify(table.concat(status_lines, "\n"), vim.log.levels.INFO)
end

-- }}}

return M
