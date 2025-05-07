# RockyDocs Environment for Neovim

Introduction to nvim-rockydocs

Nvim-rockydocs is a Neovim plugin designed to provide a dedicated interface for writing documentation for the Rocky Linux Documentation Project. This plugin is tailored to streamline the documentation process, making it easier for contributors to create, edit, and manage high-quality documentation for Rocky Linux.
Key Features

- Streamlined Documentation Workflow: nvim-rockydocs offers a simplified workflow for writing and managing documentation, ensuring that contributors can focus on content creation.
- MkDocs Integration: The plugin integrates seamlessly with MkDocs, allowing for easy serving, building, and deployment of documentation.
- Virtual Environment Management: Contributors can manage Python virtual environments directly within Neovim, ensuring reproducibility and isolation for documentation projects.
- Customizable: The plugin supports customization options to adhere to the Rocky Linux documentation style and standards.
- Browser Preview: Contributors can preview their documentation in real-time, ensuring accuracy and quality before publication.

Purpose

The primary purpose of nvim-rockydocs is to provide a user-friendly interface for Rocky Linux contributors to write, edit, and manage documentation. By leveraging the power of Neovim and MkDocs, this plugin aims to:

- Simplify the documentation process
- Improve documentation quality and consistency
- Enhance contributor experience
- Foster a culture of documentation within the Rocky Linux community

Benefits

By using nvim-rockydocs, contributors can benefit from:

A streamlined documentation workflow
Easy management of virtual environments and dependencies
Real-time preview and feedback
Customization options to adhere to Rocky Linux documentation standards
Improved overall documentation quality and consistency

Getting Started

To begin using nvim-rockydocs, simply follow the installation instructions provided in the plugin's documentation. Once installed, explore the various commands and features to discover how nvim-rockydocs can enhance your documentation workflow for Rocky Linux.

With nvim-rockydocs, contribute to the Rocky Linux Documentation Project with ease, and help create high-quality documentation that benefits

Installing nvim-rockydocs with lazy.nvim

Step 1: Add nvim-rockydocs to your lazy.nvim configuration

In your Neovim configuration file (usually init.lua), add the following line to your lazy.nvim setup:

```lua
{ 'ambaradan/nvim-rockydocs' }
```

This will tell lazy.nvim to install the nvim-rockydocs plugin from the ambaradan/nvim-rockydocs GitHub repository.
Step 2: Install nvim-rockydocs using lazy.nvim

Save your init.lua file and restart Neovim. Then, run the following command in Neovim:

```text
:Lazy sync
```

or

```text
:Lazy install
```

This will install nvim-rockydocs.

Step 3: Load nvim-rockydocs

To load nvim-rockydocs, you can add configuration options to your init.lua file. For example:

```lua
require("nvim-rockydocs")
```

## RockyDocs Commands

The "nvim-rockydocs" plugin provides a set of commands under the "RockyDocs" namespace, which are designed to streamline the documentation workflow for the Rocky Linux Documentation Project. These commands are the primary features of the plugin and are used to serve, build, and manage documentation projects.

The following RockyDocs commands are available:

- RockyDocsSetup: This command sets up a new RockyDocs project by cloning the repository and installing the required dependencies. It checks if a virtual environment is active and installs the requirements using the pip package manager.
- RockyDocsServe: This command serves the documentation project using MkDocs. It activates the virtual environment, checks if MkDocs is installed, and starts the server in the background. The server can be stopped using the RockyDocsStop command.
- RockyDocsStop: This command stops the currently running MkDocs server.
- RockyDocsBuild: This command builds the documentation project using MkDocs. It activates the virtual environment, checks if MkDocs is installed, and builds the documentation.
- RockyDocsStatus: This command displays the status of the documentation project, including whether a virtual environment is active, whether MkDocs is installed, and whether the server is running.

Usage

To use these RockyDocs commands, you can execute them in Neovim using the `:RockyDocs<Command>` syntax. For example:

- :RockyDocsSetup to set up a new RockyDocs project
- :RockyDocsServe to serve the documentation project
- :RockyDocsStop to stop the MkDocs server
- :RockyDocsBuild to build the documentation project
- :RockyDocsStatus to display the project status

These RockyDocs commands provide a convenient way to manage documentation projects for the Rocky Linux Documentation Project, making it easier to create, edit, and deploy high-quality documentation.

## PyVenv Commands

The "nvim-rockydocs" plugin provides a set of utility commands under the "PyVenv" namespace, which are designed to manage Python virtual environments directly within Neovim. These commands are not part of the main plugin functionality but rather serve as auxiliary tools to support the plugin's primary features.
PyVenv Commands

The following PyVenv commands are available as utilities in the "nvim-rockydocs" plugin:

- PyVenvCreate: This command creates a new Python virtual environment for the current project. The environment is created using the python -m venv command, and the virtual environment directory is stored in the venvs_dir path specified in the plugin's configuration.
- PyVenvActivate: This command activates the virtual environment for the current project. If the virtual environment does not exist, it will be created first. The VIRTUAL_ENV environment variable is set to the path of the active virtual environment, and the PATH environment variable is updated to prioritize the virtual environment's bin directory.
- PyVenvDeactivate: This command deactivates the currently active virtual environment, restoring the original environment variables.
- PyVenvStatus: This command displays the status of the virtual environment, including whether it is active, the Python version, and the path to the virtual environment.
- PyVenvRemove: This command removes the virtual environment for the current project.

Usage

To use these PyVenv commands, you can execute them in Neovim using the `:PyVenv<Command>` syntax. For example:

- :PyVenvCreate to create a new virtual environment
- :PyVenvActivate to activate the virtual environment
- :PyVenvDeactivate to deactivate the virtual environment
- :PyVenvStatus to display the virtual environment status
- :PyVenvRemove to remove the virtual environment

These PyVenv commands provide a convenient way to manage Python virtual environments directly within Neovim, making it easier to work with the "nvim-rockydocs" plugin and other projects that require virtual environments.
