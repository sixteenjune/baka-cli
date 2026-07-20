# baka-cli

*The STRONGEST command-line tool, obviously~*

A Lua-based system utility CLI for Gentoo/Arch desktops, themed after Cirno from Touhou Project. Commands are plain Lua modules, config lives in one flat file, and everything degrades gracefully when a tool isn't installed.

## Installation

```bash
git clone https://github.com/sixteenjune/baka-cli
cd baka-cli
chmod +x baka.lua
./baka.lua init
```

`baka init` detects your OS/arch and walks you through the rest:

* **Package manager** — Gentoo (portage) or Arch Linux (pacman + yay/paru)
* **Init system** — systemd or OpenRC
* **VPN mesh** — netbird, tailscale, or none
* **Privilege escalation** — doas or sudo
* **Color palette** — `none`, `ice` (classic Cirno, cool/mature blues), or `soda` (neon, bubblier)

It also installs `~/.local/bin/baka` as a symlink to this script, so `baka` works globally once that's on your `PATH`.

**`baka init` is idempotent** — run it again any time to tweak one setting. Every question shows your current value and pressing enter keeps it; nothing else gets touched.

## Usage

```bash
baka <command> [args]
```

Run `baka help` any time for the full list. Summary:

| Command | Description |
|---|---|
| `init` | First-time setup, or re-run to tweak settings |
| `help` | Show the command list |
| `status` | Distro, package count, hardware, services, VPN -- one glance |
| `rebuild` | Full system rebuild |
| `update` | Sync + update packages |
| `clean` | Clear out old packages and orphans |
| `backup` | Timestamped tar.gz backups of dotfiles + `/etc` configs into `~/backups/` |
| `why <pkg>` | What depends on `<pkg>` |
| `files <pkg>` | What files `<pkg>` owns |
| `ports` | Listening ports and owning processes, TCP/UDP color-coded |
| `network` | A prettier `ip a`, plus VPN status |
| `storage` | Disk usage breakdown (`/tmp` / `~` / other), swap, largest items in `~` |

Commands that touch the package manager (`rebuild`, `update`, `clean`) and privileged backups run through whichever of `doas`/`sudo` you picked in `baka init`. Ctrl+C during any of these is reported with its real exit code (130), consistently, and that code propagates to `baka`'s own process exit status -- so `baka update; echo $?` reflects what actually happened.

## Creating commands

Copy `commands/_template.lua` to `commands/<name>.lua`, then register it in `commands/init.lua`.

If your command needs the distro/init-system/VPN backend, `require` it **inside** `M.run`, not at the top of the file -- `commands/init.lua` (the registry) eagerly loads every command module, and a top-level require would trip the backend's config check before the user ever picked a command.

## Project layout

<<<<<<< HEAD
=======
```text
rebuild   Rebuild the system
update    Update system packages/configuration
init      Initialize baka
status    Fastfetch-like status report, defaults running services "iwd", "dbus", "netbird"
>>>>>>> eea56e815c06553cdad4e64db43adf8e323926f5
```
baka.lua                entrypoint
commands/
  init.lua               COMMAND REGISTRY (not the `baka init` command -- see its header comment)
  setup.lua               `baka init` -- the actual setup wizard
  help.lua, status.lua, rebuild.lua, update.lua, clean.lua,
  backup.lua, why.lua, files.lua, ports.lua, network.lua, storage.lua
  _template.lua           starting point for new commands
lib/
  config.lua              ~/.config/baka/baka.conf read/write
  colors.lua               palette-aware ANSI colors (none/ice/soda + neon accent)
  icons.lua                 Nerd Font glyphs, used sparingly
  anim.lua                   oscillating-dot loading flourish
  exec.lua                    shell exec helpers with reliable cross-Lua-version exit codes
  sudo.lua                     doas/sudo wrapper, honors configured tool
  format.lua                    tables, bars, aligned columns, byte formatting
modules/
  distro/                gentoo.lua / arch.lua backends (rebuild/update/clean/why/files/package_count)
  initsys/                 systemd.lua / openrc.lua backends
  vpn/                       netbird.lua / tailscale.lua / none.lua backends
```

## Requirements

<<<<<<< HEAD
* Lua 5.1+ (developed/tested against 5.1)
* `doas` or `sudo`
* A Nerd Font in your terminal, if you want the icons to render as icons instead of boxes
* Gentoo or Arch, systemd or OpenRC
* Optional: `netbird` or `tailscale` for VPN status; `pacman-contrib` (for `pactree`) on Arch
=======
* Lua 5.1+
* A Unix-like operating system
>>>>>>> eea56e815c06553cdad4e64db43adf8e323926f5
