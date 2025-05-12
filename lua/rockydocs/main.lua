local M = {}

local utils = require("rockydocs.utils")
local configs = require("rockydocs.configs")

-- Install MkDocs for RockyDocs Project {{{

function M.rockydocs()
	-- Check if the virtual environment is active
	if not utils.venv_is_active() then
		vim.notify("Please activate a virtual environment first", vim.log.levels.ERROR)
		return false
	end

	-- Create buffer for all output
	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = 80,
		height = 20,
		col = (vim.o.columns - 80) / 2,
		row = (vim.o.lines - 20) / 2,
		style = "minimal",
		border = "rounded",
		title = "RockyDocs Setup",
		title_pos = "center",
	})

	local lines = { "Starting RockyDocs setup..." }
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

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

	-- Clone the repository
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
					"",
					"✖ Failed to clone repository",
					"Exit code: " .. tostring(exit_code),
				})
				vim.notify("Failed to clone repository", vim.log.levels.ERROR)
				return
			end

			append_to_buffer({
				"",
				"✔ Successfully cloned repository",
				"",
				"Installing requirements...",
			})

			-- Install requirements
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
							"",
							"✖ Failed to install requirements",
							"Exit code: " .. tostring(pip_exit_code),
						})
						vim.notify("Failed to install requirements", vim.log.levels.ERROR)
					else
						append_to_buffer({
							"",
							"✔ Successfully installed requirements",
							"",
							"RockyDocs environment ready!",
							"Use :RockydocsServe to run it",
						})
						vim.notify("RockyDocs setup completed", vim.log.levels.INFO)
					end

					-- Cleanup files
					local files = { "requirements.txt", "README.md", "LICENSE", ".git" }
					for _, file in ipairs(files) do
						if vim.fn.filereadable(file) == 1 then
							os.remove(file)
						elseif vim.fn.isdirectory(file) == 1 then
							vim.fn.jobstart("rm -rf " .. file, { detach = true })
						end
					end

					-- Close window after delay
					vim.defer_fn(function()
						if vim.api.nvim_win_is_valid(win) then
							vim.api.nvim_win_close(win, true)
						end
					end, 5000)
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

function M.serve(opts)
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

	-- Determine the port to use
	local port = opts and opts.port or configs.config.mkdocs_server.default_port

	-- Check if port is within the allowed range
	if port < configs.config.mkdocs_server.port_range_start or port > configs.config.mkdocs_server.port_range_end then
		vim.notify("Port out of allowed range. Using default port.", vim.log.levels.WARN)
		port = configs.config.mkdocs_server.default_port
	end

	local cmd = string.format("%s -m mkdocs serve -q -a localhost:%d", utils.get_python_path(), port)

	vim.notify(string.format("Starting RockyDocs server on port %d...", port), vim.log.levels.INFO)

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
			configs.state.current_server_port = nil
		end,
	})

	-- Store the current server port
	configs.state.current_server_port = port

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
