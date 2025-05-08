local M = {}

-- Default configuration (single source of truth)
M.default_config = {
	venvs_dir = vim.fn.stdpath("data") .. "/venvs",
	preserved_paths = {
		vim.fn.stdpath("data") .. "/mason/bin",
		"/usr/local/bin",
		"/usr/bin",
		os.getenv("HOME") .. "/.local/bin",
	},
	mkdocs_server = {
		default_port = 8000,
		port_range_start = 8000,
		port_range_end = 8100,
	},
}

-- Current configuration (gets merged with defaults during setup)
M.config = vim.deepcopy(M.default_config)

-- State management
M.state = {
	original_path = vim.env.PATH,
	original_python_path = vim.fn.exepath("python"),
	active = false,
	current_server_port = nil,
	server_job_id = nil,
}

return M
