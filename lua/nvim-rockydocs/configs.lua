local M = {}

-- Configuration
M.config = {
	venvs_dir = vim.fn.stdpath("data") .. "/venvs",
	preserved_paths = {
		vim.fn.stdpath("data") .. "/mason/bin",
		"/usr/local/bin",
		"/usr/bin",
		os.getenv("HOME") .. "/.local/bin",
	},
	-- Add default port configuration
	mkdocs_server = {
		default_port = 8000, -- Default MkDocs serve port
		port_range_start = 8000,
		port_range_end = 8100,
	},
	server_job_id = nil,
}

-- State management
M.state = {
	original_path = vim.env.PATH,
	original_python_path = vim.fn.exepath("python"),
	active = false,
}

return M
