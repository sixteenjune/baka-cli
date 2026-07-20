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
* **Compiler** — gcc or llvm/clang (used by `baka kernel`)
* **Bootloader** — grub or limine (used by `baka kernel`)
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
| `kernel` | Build + install from `/usr/src/linux`, update the bootloader |
| `services` | Arrow-key start/stop menu for systemd/OpenRC services |
| `temp` | Thermal zones, CPU governor, turbo state, power manager |
| `battery` | Capacity, health, cycle count, charge thresholds |
| `cpu` | Live per-core usage + temp, running min/avg/p95/max |
| `doctor` | Checks baka's own setup for problems |

Commands that touch the package manager (`rebuild`, `update`, `clean`) and privileged backups run through whichever of `doas`/`sudo` you picked in `baka init`. Ctrl+C during any of these is reported with its real exit code (130), consistently, and that code propagates to `baka`'s own process exit status -- so `baka update; echo $?` reflects what actually happened.

### `baka kernel`

Builds and installs from `/usr/src/linux` (compile, `modules_install`, `install`, then `dracut --force`), then updates the bootloader. Compiler (gcc/llvm) and bootloader (grub/limine) come from `baka init`:

* **llvm** finds the highest-numbered `/usr/lib/llvm/*/bin` and prepends it to `PATH` for the build, matching what `env PATH="/usr/lib/llvm/N/bin:$PATH"` does in a shell alias.
* **grub** runs `grub-mkconfig -o /boot/grub/grub.cfg` afterward. **limine** does nothing -- it discovers kernels on its own.

`baka clean` also offers to remove stale `/lib/modules/*` directories left behind by manual kernel builds (distro package managers don't know about them, since they were never installed as packages) -- it always asks before deleting anything.

### `baka services`

Arrow-key menu for systemd/OpenRC services:

```
up/down   move
enter     toggle start/stop
r         restart
t         toggle view (see below)
q / esc   quit
```

Needs a real terminal (not a pipe/script). Privileged actions briefly drop out of the menu's input mode so the doas/sudo password prompt behaves normally, then return to the menu afterward.

**The `t` toggle**: the default view has a real gap on both init systems -- OpenRC's `rc-status` only reports services it's already tracking (in a runlevel, or started this boot), so a manually-installed daemon can exist, even run, and never show up. systemd's `--user` units live on a completely separate session bus from the system manager, so the default view can't see them at all, full stop. Rather than merge both sources into one list (and blur which privilege level an action would use), `t` switches explicitly between them:

* **OpenRC**: primary (`rc-status`) <-> every script under `/etc/init.d`, queried individually
* **systemd**: system scope <-> `--user` scope (actions here run unelevated, over your own session bus -- doas/sudo would target root's session, not yours)

### `baka cpu`

Live per-core usage and temperature, sampling `/proc/stat` once a second. Tracks min/avg/p95/max over the whole session so far, not just a rolling window. `q`/`esc`/Ctrl+C to stop.

### `baka doctor`

Read-only checklist: config completeness, the `~/.local/bin/baka` symlink and whether it's on `PATH`, whichever of doas/sudo is configured, distro-specific tooling (equery/eclean on Gentoo, your AUR helper + pactree on Arch), and anything `baka kernel` needs (dracut, grub-mkconfig if applicable). Exits non-zero if anything outright failed.

## Creating commands

Copy `commands/_template.lua` to `commands/<name>.lua`, then register it in `commands/init.lua`.

If your command needs the distro/init-system/VPN backend, `require` it **inside** `M.run`, not at the top of the file -- `commands/init.lua` (the registry) eagerly loads every command module, and a top-level require would trip the backend's config check before the user ever picked a command.
```

## Requirements

* Lua 5.1+ (developed/tested against 5.1)
* `doas` or `sudo`
* A Nerd Font in your terminal, if you want the icons to render as icons instead of boxes
* Gentoo or Arch, systemd or OpenRC
* Optional: `netbird` or `tailscale` for VPN status; `pacman-contrib` (for `pactree`) on Arch
* Optional: `dracut` and (`grub` or `limine`) for `baka kernel`
