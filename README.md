# baka-cli

A small Lua-based system utility CLI for Gentoo/Arch desktops. Commands are Lua modules; configuration is stored in a single file.

## Quick start

```bash
git clone https://github.com/sixteenjune/baka-cli
cd baka-cli
chmod +x baka.lua
./baka.lua init
```

Run `baka help` for full usage. Basic pattern:

baka <command> [args]

## Common commands

- init — initial setup or reconfigure
- help — show commands
- status — system overview
- update — sync and update packages
- rebuild — full system rebuild
- clean — remove old packages and orphans
- backup — create timestamped backups of dotfiles and /etc
- kernel — build and install kernel from /usr/src/linux
- services — interactive start/stop menu for systemd/OpenRC
- cpu, temp, battery, network, storage, ports — system info
- doctor — checks baka's setup

## Creating commands

Copy `commands/_template.lua` to `commands/<name>.lua` and register it in `commands/init.lua`.
If a command needs distro/init/VPN backends, require those modules inside `M.run` (not at top-level).

## Requirements

- Lua 5.1+
- doas or sudo
- Gentoo or Arch; systemd or OpenRC

Optional: Nerd Font for icons, netbird/tailscale for VPN status, dracut and grub/limine for kernel workflows.

Contributions welcome — open a PR with changes.
