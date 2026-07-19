# baka-cli

A simple Lua-based command runner for automating system tasks.

`baka` provides a lightweight CLI framework where commands are written as Lua modules. It is designed to be simple, hackable, and easy to extend.

## Features

* Lightweight Lua CLI
* Modular command system
* Easy command creation
* Simple configuration and library structure
* Designed for personal automation workflows

## Installation

Clone the repository:

```bash
git clone https://github.com/sixteenjune/baka-cli
cd baka-cli
```

Make `baka.lua` executable:

```bash
chmod +x baka.lua
```

Optionally add it to your PATH:

```bash
ln -s "$(pwd)/baka.lua" ~/.local/bin/baka
```

## Usage

Run commands with:

```bash
baka <command>
```

Available commands:

```text
rebuild   Rebuild the system
update    Update system packages/configuration
init      Initialize baka
```

Example:

```bash
baka rebuild
```

## Adding Commands

Commands are stored in the `commands/` directory.

Create a new command:

```lua
-- commands/example.lua

local M = {}

function M.run(args)
    print("Hello from baka!")
end

return M
```

Register it in `commands/init.lua`:

```lua
M.example = require("commands.example").run
```

You can now run:

```bash
baka example
```

## Project Structure

```
.
├── baka.lua
├── commands
│   ├── init.lua
│   ├── rebuild.lua
│   ├── update.lua
│   └── initialize.lua
├── config
├── lib
│   ├── colors.lua
│   ├── config.lua
│   └── sudo.lua
└── modules
```

## Requirements

* Lua 5.3+
* Linux operating system (Only supports Gentoo for now)

## License

MIT License
