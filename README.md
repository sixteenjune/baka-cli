# baka-cli

A simple Lua-based, Cirno-approved, command utility for automating system tasks.

`baka` is a lightweight CLI framework where commands are written as Lua modules. It is designed to be simple, easy to extend, and useful for personal automation workflows.

## Features

* Lightweight Lua CLI
* Modular command system
* Easy command creation
* Simple configuration system
* Built-in command template for extending functionality

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

Run the initializer:

```bash
/path/to/baka-cli/baka.lua init
```

Make sure `~/.local/bin` is in your `PATH`.

After initialization, you can run:

```bash
baka <command>
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
status    Fastfetch-like status report, defaults running services "iwd", "dbus", "netbird"
```

Example:

```bash
baka rebuild
```

## Creating Commands

Commands are Lua modules stored in the `commands` directory.

A command template is provided:

```text
commands/_template.lua
```

Use it as a starting point when creating new commands, then register the command in `commands/init.lua`.

## Requirements

* Lua 5.1+
* A Unix-like operating system
