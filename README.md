# Introduction

Nvim-rockydocs is a Neovim plugin designed to provide a dedicated interface for
writing documentation for the Rocky Linux Documentation Project. This plugin is
tailored to streamline the documentation process, making it easier for
contributors to create, edit, and manage high-quality documentation for Rocky
Linux.

## Key Features

- **Streamlined Documentation Workflow**: nvim-rockydocs offers a simplified
  workflow for writing and managing documentation, ensuring that contributors
  can focus on content creation.
- **MkDocs Integration**: The plugin integrates seamlessly with MkDocs, allowing for
  easy serving, building, and deployment of documentation.
- **Virtual Environment Management**: Contributors can manage Python virtual
  environments directly within Neovim, ensuring reproducibility and isolation
  for documentation projects.
- **Customizable**: The plugin supports customization options to adhere to the Rocky
  Linux documentation style and standards.
- **Browser Preview**: Contributors can preview their documentation in real-time,
  ensuring accuracy and quality before publication.

## Purpose

The primary purpose of nvim-rockydocs is to provide a user-friendly interface
for Rocky Linux contributors to write, edit, and manage documentation.  By
leveraging the power of Neovim and MkDocs, this plugin aims to:

- Simplify the documentation process
- Improve documentation quality and consistency
- Enhance contributor experience

## Benefits

By using *nvim-rockydocs*, contributors can benefit from:

- A streamlined documentation workflow
- Easy management of virtual environments and dependencies
- Real-time preview and feedback
- Customization options to adhere to Rocky Linux documentation standards
- Improved overall documentation quality and consistency

## Getting Started

Once installed, explore the various commands and features to discover how
*nvim-rockydocs* can enhance your documentation workflow for *Rocky Linux*.
With nvim-rockydocs, contribute to the [Rocky Linux Documentation
Project](https://docs.rockylinux.org/) with ease, and help create high-quality
documentation that benefits

# Install

## Install with lazy.nvim

**Step 1**: Add nvim-rockydocs to your lazy.nvim configuration

In your Neovim configuration file (usually `plugins/init.lua`), add the
following line to your *lazy.nvim* setup:

```lua
{ 'ambaradan/nvim-rockydocs' }
```

This will tell lazy.nvim to install the nvim-rockydocs plugin from the
*ambaradan/nvim-rockydocs* GitHub repository.

**Step 2**: Install nvim-rockydocs using lazy.nvim

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

*Rocks.nvim* is a plugin manager for *Neovim*, built using *Lua*. It aims to
provide an efficient and easy-to-use way to manage plugins in your Neovim
configuration.

To install the nvim-rockydocs rock, run the following command in Neovim:

```text
:Rocks install nvim-rockydocs dev
```

This will install the nvim-rockydocs rock and its dependencies.

# Config

The nvim-rockydocs plugin utilizes Neovim's packadd command to load its
dependencies and functionality on demand. This approach allows the plugin to be
loaded only when needed, reducing Neovim's startup time and improving overall
performance.

The plugin's entry point is located in the `plugin/nvim-rockydocs.vim` file,
which checks if the plugin has already been loaded and sets a flag to prevent
redundant loading. It then invokes a Lua function to set up the plugin's
configuration.

The use of packadd by nvim-rockydocs eliminates the need for explicit
configuration with *lazy.nvim*. Users can simply install the plugin and start
using it without having to add any additional configuration to their *lazy.nvim
setup*.

**NOTE:** Note about the `packadd` feature The packadd command is a feature in
Neovim that allows users to load plugins on demand, rather than during Neovim
startup. This provides a more efficient and flexible way to manage plugins, as
it enables users to load only the plugins they need for a specific task or
project.

## mkdocs serve port

One of the key features of Mkdocs is the ability to serve your documentation
locally for preview and testing purposes. By default, Mkdocs serves the site on
port 8000. However, users may need to change this port due to various reasons
such as port conflicts or specific project requirements.  To change the default
port used by Mkdocs when serving your documentation, you can specify the port in
the `require("rockydocs").setup()` function. This function is used to configure
nvim-rockydocs to allow setting the Mkdocs serve port.

Here is an example configuration snippet that demonstrates how to set the Mkdocs
serve port to 8001:

```lua
-- Specify the port you want to use for mkdocs serve
require("rockydocs").setup({ mkdocs_port = 8001, })
```

In this example, replace 8001 with the port number you wish to use. After
setting up nvim-rockydocs with this configuration, when you run the Mkdocs
server, it will use the specified port instead of the default port 8000.

## LSP availability

> Language servers are external tools that provide features such as syntax
> checking, code completion, and debugging for a specific programming language.

The PATH environment variable is a crucial component in the plugin
nvim-rockydocs as it allows you to specify the location of the language server
executables within the virtual environment. This ensures that the plugin can
access and utilize the language servers during documentation generation,
providing accurate and up-to-date information for your projects.

When start the language server, nvim-rockydocs uses the PATH environment
variable to locate the language server executable. The plugin executes the
language server using the `vim.fn.system` function, which searches for the
executable in the directories specified in the PATH variable.

## preserved_paths

The preserved_paths option in configs.lua is used to specify a list of
directories that should be preserved in the PATH environment variable when using
nvim-rockydocs with a language server installed with *mason.nvim*.

The purpose of preserved_paths is to ensure that certain directories are always
included in the PATH environment variable, even when nvim-rockydocs is running.
This is useful when you have other tools or executables that need to be accessed
from the PATH environment variable.  When nvim-rockydocs starts, it sets the
PATH environment variable to the value specified in the path option. However, if
preserved_paths is set, nvim-rockydocs will also append the directories
specified in preserved_paths to the PATH environment variable.

This ensures that the directories specified in preserved_paths are always
included in the PATH environment variable, even when nvim-rockydocs is running.
By using preserved_paths you can ensure that certain directories are always
included in the PATH environment variable, even when using nvim-rockydocs with a
language server installed with `mason.nvim`.

# RockyDocs Commands

The "nvim-rockydocs" plugin provides a set of commands under the "RockyDocs"
namespace, which are designed to streamline the documentation workflow for the
Rocky Linux Documentation Project. These commands are the primary features of
the plugin and are used to setup, serve, build, and browse the documentation
projects.

The following RockyDocs commands are available:

- **RockyDocsSetup**: This command sets up a new RockyDocs project by cloning
  the repository and installing the required dependencies. It checks if a
  virtual environment is active and installs the requirements using the pip
  package manager.
- **RockyDocsServe**: This command serves the documentation project using
  MkDocs. It activates the virtual environment, checks if MkDocs is installed,
  and starts the server in the background. The server can be stopped using the
  RockyDocsStop command.
- **RockyDocsStop**: This command stops the currently running MkDocs server.
- **RockyDocsBuild**: This command builds the documentation project using
  MkDocs. It activates the virtual environment, checks if MkDocs is installed,
  and builds the documentation.
- **RockyDocsStatus**: This command displays the status of the documentation
  project, including whether a virtual environment is active, whether MkDocs is
  installed, and whether the server is running.
- **RockyDocsOpen**: This command open the RockyDocs documentation in the
  default web browser. This command is a convenient way to preview the
  documentation while you're working on it.

## Usage

To use these RockyDocs commands, you can execute them in Neovim using the
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
"PyVenv" namespace, which are designed to manage Python virtual environments
directly within Neovim. These commands are not part of the main plugin
functionality but rather serve as auxiliary tools to support the plugin's
primary features. PyVenv Commands

The following PyVenv commands are available as utilities in the "nvim-rockydocs"
plugin:

- **PyVenvCreate**: This command creates a new Python virtual environment for
  the current project. The environment is created using the python -m venv
  command, and the virtual environment directory is stored in the venvs_dir path
  specified in the plugin's configuration.
- **PyVenvActivate**: This command activates the virtual environment for the
  current project. If the virtual environment does not exist, it will be created
  first. The VIRTUAL_ENV environment variable is set to the path of the active
  virtual environment, and the PATH environment variable is updated to
  prioritize the virtual environment's bin directory.
- **PyVenvDeactivate**: This command deactivates the currently active virtual
  environment, restoring the original environment variables.
- **PyVenvStatus**: This command displays the status of the virtual environment,
  including whether it is active, the Python version, and the path to the
  virtual environment.
- **PyVenvRemove**: This command removes the virtual environment for the current
  project.

## Usage

To use these PyVenv commands, you can execute them in Neovim using the
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

# Creating the Environment

Creating a Rocky Linux documentation environment is a straightforward process
that involves a few key steps. Begin by setting up a dedicated project folder,
which will serve as the foundation for your documentation efforts.  Next, launch
nvim, a powerful and flexible text editor, within this folder. From there,
create a Python virtual environment to isolate your project's dependencies and
ensure seamless execution.  Activate this environment to enable the installation
of necessary packages, including mkdocs and mkdocs-material, which are essential
for building and publishing your documentation. Once these components are in
    place, verify that your setup is complete and functional by running a status
    check.

By following these simple steps, you can quickly establish a robust and
efficient documentation environment using nvim-rockydocs.

**Step 1**: Create an empty Project Folder

To start, create an empty folder for your project. This folder will serve as the
root directory for your documentation environment. You can create the folder
using the `mkdir` command in the terminal:

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

Activate the virtual environment using PyVenvActivate. This step is crucial as
it allows you to install packages specific to your project without affecting the
system Python environment:

```text
:PyVenvActivate
```

**Step 5**: Install Necessary Packages and Prepare the Project Structure

With the virtual environment activated, use RockyDocsSetup to install mkdocs and
mkdocs-material using Python pip, and prepare the basic structure for your
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
and project structure, providing feedback on whether the setup is successful and
ready for documentation work.

By following these steps, you have successfully created a Rocky Linux
documentation environment using nvim-rockydocs. This environment is now ready
for you to create, manage, and publish your documentation projects efficiently,
    utilizing the powerful features of mkdocs and the convenience of nvim for
    editing and managing the documents.

### Utilizing Rocky Linux Documentation Environment for daily use

After setting up the Rocky Linux documentation environment with
*nvim-rockydocs*, it's time to explore its daily use. This involves a seamless
workflow that includes launching the mkdocs server, editing documentation, and
stopping the server when finished.

### Launching the Mkdocs Server

To start working on your documentation, use the `:RockyDocsServe` command within
*nvim*. This command launches the mkdocs server, making your documentation
available for preview at `http://localhost:8000`. With the server running, you
can edit your documentation files, and the changes will be reflected in
real-time in your web browser.

### Editing Documentation

While the mkdocs server is running, you can freely edit your documentation files
using nvim. Take advantage of nvim powerful editing features, such as syntax
highlighting, auto-completion, and version control integration, to efficiently
create and refine your documentation. As you save changes to your files, the
mkdocs server will automatically rebuild your documentation site, allowing you
to preview the updated content in your browser.

### Stopping the Mkdocs Server

Once you've completed your editing tasks, it's essential to stop the mkdocs
server to free up system resources. Use the `:RockyDocsStop` command to
gracefully stop the server. This ensures that the server process is terminated
cleanly, preventing any potential issues or conflicts with other system
processes.

By following this workflow, you can efficiently create, edit, and publish
high-quality documentation using the Rocky Linux documentation environment with
nvim-rockydocs.

### Utilizing RockyDocsBuild for Previewing Documentation

While the primary focus of the Rocky Linux documentation environment is on
creating, editing, and mainly previewing documentation, there may be instances
where you need to build your documentation for a more polished preview.
Although building and deploying documentation is outside the initial scope of
the project, nvim-rockydocs provides a useful command, `:RockyDocsBuild`, to
help facilitate this process.

### Building Documentation for Preview

The `:RockyDocsBuild` command leverages mkdocs built-in functionality to
generate a static HTML site from your documentation files. This resulting site
can be used for a more comprehensive preview of your documentation, allowing you
to see how it will look when finalized.  When you run `:RockyDocsBuild`, mkdocs
compiles your documentation into a fully functional website, complete with
navigation, search functionality, and styling based on the mkdocs-material
theme.

### Use Cases for RockyDocsBuild

Although not the primary intention of the project, using `:RockyDocsBuild` can
be beneficial in several scenarios:

- **Comprehensive Preview**: After making significant changes or additions to
  your documentation, building the site provides a thorough preview of how the
  documentation will appear.
- **Testing**: Before sharing or deploying your documentation, building it with
  :RockyDocsBuild allows you to test links, images, and other media to ensure
  they are correctly referenced.
- **Localization and Theme Testing**: If you're using custom themes or
  localization, building your documentation helps verify that these aspects are
  correctly implemented.

The `:RockyDocsBuild` command offers a straightforward way to build your
documentation for a comprehensive preview. This feature can be particularly
useful for testing, verification, and quality assurance of your documentation
projects before commit.

> [!NOTE] The :RockyDocsBuild command generates a static HTML site from your
> documentation files, which is specifically designed for deployment on a web
> server, rather than for local browsing. This built version of your
> documentation is ready to be uploaded to a web server, where it can be served
> to users.

<!-- panvimdoc-ignore-start -->

# Conclusions

The Rocky Linux documentation environment, powered by nvim-rockydocs, has been
meticulously designed to facilitate the creation, editing, and previewing of
high-quality documentation for Rocky Linux contributions. By providing a
streamlined and intuitive workflow, this environment aims to empower
contributors to focus on what matters most: **creating valuable content that
enhances the Rocky Linux ecosystem**.

<!-- panvimdoc-ignore-end -->
