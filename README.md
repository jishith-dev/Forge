# Forge

**Forge** is a lightweight, Git-inspired version control system written in [Zen](https://github.com/Jishith-dev/Zen).

It provides essential version control features through a simple command-line interface, including staging, commits, history, diffs, restoration, and checkout.

## Features

- Initialize local repositories
- Stage new, modified, and deleted files
- Create commits with snapshots
- Content-addressed file storage using SHA-256 hashes
- View commit history
- Inspect staged and unstaged changes
- Restore files from the staging index
- Check out previous commits
- Protect uncommitted changes during checkout
- Force checkout when changes should be discarded
- Configure the commit author name
- Respect `.forgeignore` rules
- Modular implementation written in Zen

## Requirements

- Zen v3.0.0 or newer
- Git and curl for installation
- Android with Termux or a supported Linux environment

**Windows is not supported in this release.**

## Installation

Forge includes an installer that checks for a compatible Zen version, installs Zen if necessary, builds Forge, and installs the executable into your command path.

### Interactive installation

```bash
curl -fsSL https://raw.githubusercontent.com/Jishith-dev/Forge/main/install.sh | bash
```

### Automatic installation

Use `-y` to accept installation prompts automatically:

```bash
curl -fsSL https://raw.githubusercontent.com/Jishith-dev/Forge/main/install.sh | bash -s -- -y
```

The installer:

1. Checks whether Zen v3.0.0 or newer is installed.
2. Installs or updates Zen using its official installer when necessary.
3. Clones the Forge repository into a temporary directory.
4. Runs `zen run main.zen` to build Forge.
5. Installs the resulting `build/main` executable.
6. Removes the temporary source and build files.

On Termux, the executable is installed into `$PREFIX/bin`. On other supported Linux environments, it is installed into `~/.local/bin`.

If the installation directory is not already in your `PATH`, add it to your shell configuration.

### Verify installation

```bash
forge --version
forge --help
```

The current release reports version `1.0.0`.

## Quick Start

Initialize a repository:

```bash
mkdir my-project
cd my-project
forge init
```

Create a file:

```bash
printf 'Hello, Forge!\n' > hello.txt
```

Stage the file and create a commit:

```bash
forge stage hello.txt
forge commit "Add hello file"
```

Check the repository status:

```bash
forge status
```

View commit history:

```bash
forge log
```

View a compact history:

```bash
forge log --short
```

Modify the file and inspect the unstaged changes:

```bash
printf 'Updated content\n' > hello.txt
forge diff
```

Stage the modification and inspect staged changes:

```bash
forge stage hello.txt
forge diff --staged
```

Create another commit:

```bash
forge commit "Update hello file"
```

Restore a file from the staging index:

```bash
forge restore hello.txt
```

## Commands

| Command | Description |
| --- | --- |
| `forge init` | Initialize a repository |
| `forge stage <path...>` | Stage file changes |
| `forge status` | Display repository status |
| `forge commit "message"` | Create a commit |
| `forge log` | Display commit history |
| `forge log --short` | Display compact commit history |
| `forge diff` | Show unstaged changes |
| `forge diff --staged` | Show staged changes |
| `forge diff [path...]` | Inspect changes for selected paths |
| `forge restore <path...>` | Restore files from the staging index |
| `forge checkout <id>` | Switch to a commit |
| `forge checkout <id> --force` | Force checkout and discard conflicting changes |
| `forge config name "Name"` | Configure the commit author name |
| `forge --version` | Display the Forge version |
| `forge --help` | Display command help |

Use `forge --help` to see the command syntax supported by your installed version.

## Repository Structure

```text
Forge/
├── main.zen
├── src/
│   ├── checkout.zen
│   ├── commit.zen
│   ├── config.zen
│   ├── diff.zen
│   ├── history.zen
│   ├── init.zen
│   ├── restore.zen
│   ├── stage.zen
│   ├── status.zen
│   └── util.zen
├── zen.json
├── install.sh
├── README.md
└── LICENSE
```

## Repository Storage

Forge stores repository metadata inside the `.forge/` directory.

Its storage includes:

- File objects identified by content hashes
- Commit metadata and snapshots
- Branch references
- A staging index
- Repository configuration

Identical file contents can reuse the same stored object through content-addressed storage.

Avoid manually editing `.forge/` internals unless you understand the repository format.

## Development

Clone the source repository:

```bash
git clone https://github.com/Jishith-dev/Forge.git
cd Forge
```

Run Forge using Zen:

```bash
zen run main.zen
```

Build the executable:

```bash
zen build main.zen
```

The build output is expected at `build/main`.

## Project Status

Forge v1.0.0 is an early-stage version control system with tested core workflows.

It is inspired by Git but is not intended to be a drop-in replacement for Git. Keep backups of important files, especially before using forced checkout.

## License

Forge is licensed under the MIT License. See [LICENSE](LICENSE) for the complete license text.
