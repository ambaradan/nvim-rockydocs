<!-- vale off -->
# Introduction

nvim-rockydocs is a Neovim plugin designed to facilitate the creation and
management of Rocky Linux pages within the Neovim environment. This plugin aims
to streamline the documentation process by providing features such as automated
documentation generation, syntax highlighting, and potentially integration with
other development tools.

The nvim-rockydocs plugin provides support for the mkdocs-material theme, which
is the default theme used in the Rocky Linux Documentation site. The
mkdocs-material theme supports a range of extended Markdown tags that provide
additional formatting and layout options. The nvim-rockydocs plugin provides
native support for the mkdocs-material theme, allowing contributors to use the
extended Markdown tags and features provided by the theme.

## Key Features

The nvim-rockydocs plugin provides a range of features to enhance documentation
management within Neovim:

* Visual Consistency
    * Provides a real-time preview that exactly matches the official Rocky
      Linux documentation style
    * Ensures visual alignment with the project's design guidelines
    * Helps contributors understand how their content will appear in the final
      documentation

* Real-Time Rendering
    * Immediate visual feedback as you write
    * Allows instant verification of formatting, structure, and layout
    * Reduces back-and-forth between editing and final presentation

* Markdown Support
    * Seamless integration with Markdown syntax
    * Easy formatting of headings, lists, code blocks, and other documentation
      elements
    * Simplifies the documentation creation process

* Workflow Efficiency
    * Eliminates guesswork about final document appearance
    * Accelerates documentation writing and review processes
    * Reduces potential formatting errors

* Collaborative Editing Features
    * Helps maintain consistent documentation standards across contributors
    * Provides a uniform editing experience
    * Facilitates easier peer review and content validation

# Install

## Install with lazy.nvim

Step 1: Add nvim-rockydocs to your lazy.nvim configuration

In your Neovim configuration file (usually `plugins/init.lua`), add the
following line to your *lazy.nvim* setup:

```lua
{ 'ambaradan/nvim-rockydocs' }
```

This will tell lazy.nvim to install the nvim-rockydocs plugin from the
*ambaradan/nvim-rockydocs* GitHub repository.

Step 2: Install nvim-rockydocs using lazy.nvim

Save your init.lua file and restart Neovim. Then, run the following command in
Neovim:

```text
:Lazy sync
```

or

```text
:Lazy install
```

## Install with rocks.nvim

Rocks.nvim is a plugin manager for Neovim, built using Lua. It aims to provide
an efficient and easy-to-use way to manage plugins in your Neovim
configuration.

To install the nvim-rockydocs rock, run the following command in Neovim:

```text
:Rocks install nvim-rockydocs dev
```

This will install the nvim-rockydocs rock and its dependencies.

# Configuration

The `rockydocs/configs.lua` file serves as the central configuration management
module for the RockyDocs Neovim plugin.

### Default Configuration

The encapsulation of the default configuration within the **M.default_config**
table, includes several key settings:

* *venvs_dir*: This setting specifies the directory that will store the virtual
  environments. By default, it sets it to the Neovim data directory, appended
  *with /venvs*. This ensures the organization of all virtual environments
  created for different projects in a single location, making management
  straightforward.
* *preserved_paths*: This is a list of directories preserved in the system PATH
  when activating a virtual environment.  
  The default paths include common binary directories, such as:

    * vim.fn.stdpath("data") .. "/mason/bin" (for Mason-managed binaries)
    * /usr/local/bin
    * /usr/bin
    * os.getenv("HOME") .. "/.local/bin" (the user's local binary directory)

This setting ensures that essential commands remain accessible even during
activation of a virtual environment.

mkdocs_server: This section of the configuration handles settings related to
the MkDocs server. Key parameters include:

* *default_port*: The default port (8000) for running the MkDocs server. This
  setting can be overridden when starting the server.
* *port_range_start* and *port_range_end*: These settings define a valid range
  for port selection, helping to avoid conflicts with other applications that
      might be using the same ports.

### Current Configuration

In addition to the default settings, the M.config table represents the current
configuration used during the plugin's operation. When the plugin initializes,
this configuration merges with the default settings. Users can override
specific settings with this design without altering the defaults, providing
flexibility in configuration.

### State Management

The `M.state table` is crucial for managing the state of the RockyDocs plugin.
It tracks information such as:

* original_path: Stores the original PATH environment variable, allowing the
  plugin to restore it after deactivating a virtual environment.
* original_python_path: Keeps the path of the original Python executable in use
  before activating any virtual environment.
* active: A boolean value that indicates whether a virtual environment is
  currently active.
* current_server_port: Stores the port number for the currently running MkDocs
  server, helping to manage server status effectively.
* server_job_id: Holds the job identifier for the MkDocs server process,
  enabling the plugin to manage and monitor the server instance.

The nvim-rockydocs plugin utilizes Neovim's packadd command to load its
dependencies and functionality on demand. This approach allows loading plugins
only when needed, reducing Neovim's startup time and improving overall
performance.

The plugin's entry point is in the `plugin/nvim-rockydocs.vim` file. It checks
whether plugin loading has already occurred and sets a flag to prevent
redundant loading. It then invokes a Lua function to set up the plugin's
configuration.

The use of packadd by nvim-rockydocs eliminates the need for explicit
configuration with lazy.nvim. Users can just install the plugin and start using
it without having to add any additional configuration to their lazy.nvim setup.

NOTE: Note about the `packadd` feature. The packadd command is a feature in
Neovim that allows for loading plugins on-demand, rather than during Neovim
startup. This provides a more efficient and flexible way to manage plugins, as
users only need to load the plugins they need for a specific task or project.

## mkdocs serve port

One of the key features of Mkdocs is the ability to serve your documentation
locally for preview and testing purposes. By default, Mkdocs serves the site on
port 8000. However, users might need to change this port due to various reasons
such as port conflicts or specific project requirements.  To change the default
port used by Mkdocs when serving your documentation, you can specify the port
in the `require("rockydocs").setup()` function. This function is for
configuring nvim-rockydocs to allow setting the Mkdocs serve port.

Here is an example configuration snippet that demonstrates how to set the
Mkdocs serve port to 8001:

```lua
-- Specify the port you want to use for mkdocs serve
require("rockydocs").setup({ mkdocs_port = 8001, })
```

In this example, replace 8001 with the port number you want to use. After
setting up nvim-rockydocs with this configuration, when you run the Mkdocs
server, it will use the specified port instead of the default port 8000.

## LSP availability

> Language servers are external tools that provide features such as syntax
> checking, code completion, and debugging for a specific programming language.

The PATH environment variable is a crucial component in the plugin
nvim-rockydocs as it allows for the specification of the location of the
language server executables within the virtual environment. This ensures that
the plugin can access and utilize the language servers during documentation
generation, providing accurate and up-to-date information for your projects.

When the language server starts, nvim-rockydocs uses the PATH environment
variable to locate the language server executable. The plugin executes the
language server with the `vim.fn.system` function, which searches for the
executable in the directories specified in the PATH variable.

## preserved_paths

The preserved_paths option in configs.lua specifies a list of directories to
preserve in the PATH environment variable when using nvim-rockydocs with a
language server installed with *mason.nvim*.

The purpose of preserved_paths is to ensure that certain directories are always
included in the PATH environment variable, even when nvim-rockydocs is running.
This is useful when you have other tools or executables you need to access from
the PATH environment variable.  When nvim-rockydocs starts, it sets the PATH
environment variable to the value specified in the path option. However, if you
define preserved_paths, nvim-rockydocs will also append the directories
specified in preserved_paths to the PATH environment variable.

This ensures that the directories specified in preserved_paths are always
included in the PATH environment variable, even when nvim-rockydocs is running.
By using preserved_paths you can ensure that certain directories are always
included in the PATH environment variable, even when using nvim-rockydocs with
a
language server installed with `mason.nvim`.

# RockyDocs Commands

The "nvim-rockydocs" plugin provides a set of commands under the "RockyDocs"
namespace, designed to streamline the documentation workflow for the Rocky
Linux Documentation Project. These commands, used to setup, serve, build, and
browse the documentation project,  are the primary features of the plugin.

The following RockyDocs commands are available:

* RockyDocsSetup: This command sets up a new RockyDocs project by cloning the
  repository and installing the required dependencies. It checks if a virtual
  environment is active and installs the requirements using the pip package
  manager.
* RockyDocsServe: This command serves the documentation project using MkDocs.
  It activates the virtual environment, checks for the installation status of
  MkDocs, and starts the server in the background. You can stop the server
  using the RockyDocsStop command.
* RockyDocsStop: This command stops the currently running MkDocs server.
* RockyDocsBuild: This command builds the documentation project using MkDocs.
  It activates the virtual environment, checks for the installation status of
  MkDocs, and builds the documentation.
* RockyDocsStatus: This command displays the status of the documentation
  project, including whether a virtual environment is active,  the installation
  status of MkDocs, and whether the server is running.
* RockyDocsOpen: This command opens the RockyDocs documentation in the default
  web browser. This command is a convenient way to preview the documentation
  while you are working on it.

## Usage

To use these RockyDocs commands, you can run them in Neovim using the
`:RockyDocs<Command>` syntax. For example:

:RockyDocsSetup

: to set up a new RockyDocs project

:RockyDocsServe

: to serve the documentation project

:RockyDocsOpen

: to browse the documentation project

:RockyDocsStop

: to stop the MkDocs server

:RockyDocsBuild

: to build the documentation project

:RockyDocsStatus

:to display the project status

These RockyDocs commands provide a convenient way to manage documentation
projects for the Rocky Linux Documentation Project, making it easier to create,
edit, and deploy high-quality documentation.

# PyVenv Commands

The "nvim-rockydocs" plugin provides a set of utility commands under the
"PyVenv" namespace, designed to manage Python virtual environments directly
within Neovim. These commands are not part of the main plugin functionality,
but rather serve as auxiliary tools to support the plugin's primary features.
The following PyVenv commands are available as utilities in the
"nvim-rockydocs" plugin:

* PyVenvCreate: This command creates a new Python virtual environment for the
  current project. The python -m venv command creates the environment, and
  stores the virtual environment directory in the venvs_dir path specified in
  the plugin's configuration.
* PyVenvActivate: This command activates the virtual environment for the
  current project. If the virtual environment does not exist, it creates it
  first. The command sets the VIRTUAL_ENV environment variable to the path of
  the active virtual environment, and updates the PATH environment variable to
  prioritize the virtual environment's bin directory.
* PyVenvDeactivate: This command deactivates the currently active virtual
  environment, restoring the original environment variables.
* PyVenvStatus: This command displays the status of the virtual environment,
  including whether it is active, the Python version, and the path to the
  virtual environment.
* PyVenvRemove: This command removes the virtual environment for the current
  project.

## Usage

To use these PyVenv commands, you can run them in Neovim by using the
`:PyVenv<Command>` syntax. For example:

:PyVenvCreate

: to create a new virtual environment

:PyVenvActivate

: to activate the virtual environment

:PyVenvDeactivate

: to deactivate the virtual environment

:PyVenvStatus

: to display the virtual environment status

:PyVenvRemove

: to remove the virtual environment

These PyVenv commands provide a convenient way to manage Python virtual
environments directly within Neovim, making it easier to work with the
"nvim-rockydocs" plugin and other projects that require virtual environments.

# Getting Started

The RockyDocs Neovim Plugin is engineered to streamline the process of managing
MkDocs-based documentation projects directly within the Neovim editor. This
plugin empowers contributors to create, serve, and build documentation content
efficiently, eliminating the need to switch between the editor and a terminal
for common documentation tasks.

Upon integrating RockyDocs into your workflow, you can easily create a new
virtual environment specific to the Rocky Linux documentation project with the
:PyVenvCreate command. Once you establish the virtual environment, activate it
with :PyVenvActivate, ensuring that Mkdocs can manage all dependencies
effectively within that context. RockyDocs offers the command :RockyDocsSetup
to initialize your documentation project by cloning template files and
preparing the necessary structure.

The plugin enables you to serve the documentation locally with the
:RockyDocsServe command. This command starts a MkDocs server, providing a live
preview of the new pages in a web browser. Users can also specify ports if
needed while accessing the server at the designated address.

In addition to serving documentation, RockyDocs allows for building static
documentation files through the :RockyDocsBuild command. This is especially
useful for deploying documentation once finalized. Furthermore, users can
monitor the status of their MkDocs environment by using the :RockyDocsStatus
command, which provides information about the active virtual environment,
MkDocs installation, and any running servers.

The RockyDocs Neovim plugin significantly enhances the documentation workflow
for developers, offering powerful tools integrated within the Neovim interface,
    thus improving the efficiency and ease of managing documentation projects.

# Creating the Environment

Creating a Rocky Linux documentation environment is a straightforward process
that involves a few key steps. Begin by setting up a dedicated project folder,
which will serve as the foundation for your documentation efforts.  Next,
launch nvim, a powerful and flexible text editor, within this folder. From
there, create a Python virtual environment to isolate your project's
dependencies and ensure seamless execution.  Activate this environment to
enable the installation of necessary packages, including mkdocs and
mkdocs-material, which are essential for building and publishing your
documentation. Once these components are in place, verify that your setup is
complete and functional by running a status check.

By following these simple steps, you can quickly establish a robust and
efficient documentation environment by using nvim-rockydocs.

**Step 1**: Create an empty Project Folder

To start, create an empty folder for your project. This folder will serve as
the root directory for your documentation environment. You can create the
folder using the `mkdir` command in the terminal:

```bash
mkdir my-rocky-docs
```

Replace my-rocky-docs with the name of your choice for the project folder.

**Step 2**: Navigate into the Project Folder and launch nvim

Navigate into the newly created project folder and launch nvim:

```bash
cd my-rocky-docs nvim
```

This will open nvim in the project folder, ready for further setup.

**Step 3**: Create a Python Virtual Environment

Use PyVenvCreate to create a Python virtual environment within your project
folder. This ensures that your documentation environment's dependencies do not
conflict with the system-wide Python environment:

```text
:PyVenCreate
```

This command creates a virtual environment named `.venv` in your project folder.

**Step 4**: Activate the Virtual Environment

Activate the virtual environment by using PyVenvActivate. This step is crucial
as it allows for the installation of packages specific to your project without
affecting the system Python environment:

```text
:PyVenvActivate
```

**Step 5**: Install Necessary Packages and Prepare the Project Structure

With the virtual environment activated, use RockyDocsSetup to install mkdocs
and mkdocs-material using Python pip, and prepare the basic structure for your
documentation project:

```text
:RockyDocsSetup
```

This command installs the required packages and sets up the initial directory
structure for your documentation project, including the basic configuration for
mkdocs in `mkdocs.yml`.

**Step 6**: Check the Status of the Setup

Finally, to ensure that everything is correctly set up and ready for use, run
the RockyDocsStatus command:

```text
:RockyDocsStatus
```

This command checks the environment, virtual environment, installed packages,
and project structure, providing feedback on whether the setup is successful
and ready for documentation work.

By following these steps, you have successfully created a Rocky Linux
documentation environment by using nvim-rockydocs. This environment is now
ready for you to create, manage, and publish your documentation projects
efficiently, utilizing the powerful features of mkdocs and the convenience of
nvim for editing and managing the documents.

<!-- panvimdoc-ignore-start -->

### Utilizing Rocky Linux Documentation Environment for daily use

After setting up the Rocky Linux documentation environment with
*nvim-rockydocs*, it is time to explore its daily use. This involves a seamless
workflow that includes launching the mkdocs server, editing documentation, and
stopping the server when finished.

### Launching the Mkdocs Server

To start working on your documentation, use the `:RockyDocsServe` command
within *nvim*. This command launches the mkdocs server, making your
documentation available for preview at `http://localhost:8000`. With the server
running, you can edit your documentation files, and the changes will show in
real-time in your web browser.

### Editing Documentation

While the mkdocs server is running, you can freely edit your documentation
files using nvim. Take advantage of nvim powerful editing features, such as
syntax highlighting, auto-completion, and version control integration, to
efficiently create and refine your documentation. As you save changes to your
files, the mkdocs server will automatically rebuild your documentation site,
allowing you to preview the updated content in your browser.

### Stopping the Mkdocs Server

Once you have completed your editing tasks, it is essential to stop the mkdocs
server to free up system resources. Use the `:RockyDocsStop` command to
gracefully stop the server. This ensures the clean termination of the server
process, preventing any potential issues or conflicts with other system
processes.

By following this workflow, you can efficiently create, edit, and publish
high-quality documentation by using the Rocky Linux documentation environment
with nvim-rockydocs.

### Utilizing RockyDocsBuild for Previewing Documentation

While the primary focus of the Rocky Linux documentation environment is on
creating, editing, and mainly previewing documentation, there might be
instances where you need to build your documentation for a more polished
preview. Although building and deploying documentation is outside the initial
scope of the project, nvim-rockydocs provides a useful command,
`:RockyDocsBuild`, to help facilitate this process.

### Building Documentation for Preview

The `:RockyDocsBuild` command leverages mkdocs built-in functionality to
generate a static HTML site from your documentation files. You can use this
resulting site for a more comprehensive preview of your documentation, allowing
you to see how it will look when finalized. When you run `:RockyDocsBuild`,
mkdocs compiles your documentation into a fully functional website, complete
with navigation, search functionality, and styling based on the mkdocs-material
theme.

### Use Cases for RockyDocsBuild

Although not the primary intention of the project, using `:RockyDocsBuild` can
be beneficial in several scenarios:

* Comprehensive Preview: After making significant changes or additions to your
  documentation, building the site provides a thorough preview of how the
  documentation will appear.
* Testing: Before sharing or deploying your documentation, building it with
  :RockyDocsBuild allows for link testing, image display, and other media to
  ensure they are correctly referenced.
* Localization and Theme Testing: If you are using custom themes or
  localization, building your documentation helps verify that these aspects are
  correctly implemented.

The `:RockyDocsBuild` command offers a straightforward way to build your
documentation for a comprehensive preview. This feature can be particularly
useful for testing, verification, and quality assurance of your documentation
projects before commit.

[!NOTE] The :RockyDocsBuild command generates a static HTML site from your
documentation files, which is specifically designed for deployment on a web
server, rather than for local browsing. This built version of your
documentation is ready for uploading to a web server, where serving it to users
is possible.

<!-- panvimdoc-ignore-end -->

# Help

This plugin includes a built-in help feature to assist users in navigating its
functionalities. For detailed information, you can browse the help
documentation by using the command `:h rockydocs`. This provides quick access
to guidance on various features and usage tips directly within the environment.
For a more comprehensive overview, you can also refer to the accompanying
`doc/rockydocs.txt` file, which contains additional information and best
practices for utilizing the plugin effectively.

<!-- panvimdoc-ignore-start -->

# Conclusions

The Rocky Linux documentation environment, powered by nvim-rockydocs, is
meticulously designed to facilitate the creation, editing, and previewing of
high-quality documentation for Rocky Linux contributions. By providing a
streamlined and intuitive workflow, this environment aims to empower
contributors to focus on what matters most: **creating valuable content that
enhances the Rocky Linux ecosystem**.

<!-- panvimdoc-ignore-end -->
