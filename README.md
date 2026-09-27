# muse-linux-desktop

Give your Muse assistant hands on your Linux desktop.

This is the setup that lets Muse open her own app window every morning,
see what's on your screen, set your wallpaper, and run things inside your
live desktop session — all from a normal SSH login, no screen-sharing hacks.

## What's inside

| Component | What it does |
|---|---|
| `bin/muse` | Opens muse.ai in its own dedicated window (Linux has no native app, so this wraps it in a clean Chrome app window) |
| `bin/muse-morning-open` | Opens the Muse app every morning at 10:00, but stays quiet if it's already open |
| `sbin/cosmic-wallpaper` | Sets the wallpaper on the real, live screen — works from an SSH session |
| `sbin/as-desktop` | Runs any command inside your live desktop session (right Wayland/D-Bus env, no guessing) |
| `sbin/assistant-desktop-access` | Grants the assistant user access to the desktop sockets (Wayland, D-Bus, X11) |
| `lib/muse/apply-wallpaper` | The bit that actually writes COSMIC's wallpaper config |
| `lib/muse/desktop-env.sh` | Source this to point any shell at the on-screen desktop session |
| `docs/assistant-ssh.md` | How to set up the dedicated assistant SSH login (the trust model, step by step) |

## Requirements

- Pop!_OS (or another COSMIC desktop) — the wallpaper helpers are COSMIC-specific
- `flatpak` + ChromeDev for the `muse` launcher (or edit `bin/muse` for your browser)
- Tailscale — only needed if you want the assistant to reach the machine remotely
- A desktop user that stays logged in (the morning opener needs a live session)

## Install

```bash
git clone <this-repo>
cd muse-linux-desktop
./install.sh
```

The installer asks for your desktop username, then:

1. Copies `bin/*` to `~/.local/bin`
2. Copies `sbin/*` to `/usr/local/bin` and `lib/muse/*` to `/usr/local/lib/muse` (needs sudo)
3. Offers to add the 10:00 AM crontab entry for `muse-morning-open`

Then follow `docs/assistant-ssh.md` to create the assistant login.

## What's NOT in here

No credentials. No keys. No Tailscale addresses. No personal data of any kind.
The installer templates your username in at install time — nothing of yours
ever lands in the repo.

## Security — read this

The assistant SSH user gets passwordless sudo. That means **full control of
the machine**: it can read your files, see your screen, and run anything as you.
Only set this up if you understand that tradeoff and you trust the assistant
with that level of access. Keep the machine's disk encrypted, keep Tailscale's
access controls tight, and never expose the SSH port to the public internet.

## Origin

Built from a real, daily-driven setup on Pop!_OS. The scripts are small on
purpose — read them before you run them; there's nothing hidden in there.
