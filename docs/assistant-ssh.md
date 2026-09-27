# Assistant SSH access

This is the trust heart of the setup. Read it fully before running anything.

## The idea

Muse drives your desktop over SSH as a **dedicated, unprivileged user**
(`candy` in the original setup — pick your own name). That user gets
passwordless sudo, which means: once it's in, it can do anything on the
machine, including act as you on your live desktop.

Only set this up if you're comfortable with an AI assistant holding that
level of access to your computer.

## Step 1 — remote reachability (optional)

Install [Tailscale](https://tailscale.com/) on the machine and log in.
This gives the machine a stable private address (like `100.x.y.z`) that
only your tailnet can reach. **Do not expose SSH to the public internet.**

Tighten it further with a Tailscale ACL or `tailscale up --shields-up`
if you like.

## Step 2 — create the assistant user

```bash
ASSISTANT=candy   # pick your own name
sudo useradd -m -s /bin/bash "$ASSISTANT"
```

Give it passwordless sudo (this is the big trust grant):

```bash
echo "$ASSISTANT ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/$ASSISTANT"
sudo chmod 440 "/etc/sudoers.d/$ASSISTANT"
```

Lock password login for it — key only:

```bash
sudo passwd -l "$ASSISTANT"
```

## Step 3 — install your SSH key

From the machine where the assistant connects **from**, generate a key if
you don't have one:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "muse-assistant"
```

Install the public half on the desktop machine:

```bash
sudo -u "$ASSISTANT" mkdir -p "/home/$ASSISTANT/.ssh"
sudo -u "$ASSISTANT" chmod 700 "/home/$ASSISTANT/.ssh"
# paste id_ed25519.pub into authorized_keys:
sudo -u "$ASSISTANT" tee -a "/home/$ASSISTANT/.ssh/authorized_keys" < id_ed25519.pub
sudo -u "$ASSISTANT" chmod 600 "/home/$ASSISTANT/.ssh/authorized_keys"
```

## Step 4 — connect

```bash
ssh -i ~/.ssh/id_ed25519 "$ASSISTANT"@<tailscale-ip-or-hostname>
```

On first connect, verify the host key out-of-band (compare the fingerprint
shown with `ssh-keygen -l -f /etc/ssh/ssh_host_ed25519_key.pub` run on the
machine itself). If the host key ever changes unexpectedly, **stop and
investigate** — don't just accept it.

## Step 5 — grant desktop access

```bash
sudo /usr/local/bin/assistant-desktop-access
```

This opens the Wayland/D-Bus/X11 sockets to the assistant user. Re-run it
after reboots (or wire it into a login autostart) since `/run` is recreated
at boot.

From here the assistant can:

- `as-desktop <command>` — run things in your live session
- `cosmic-wallpaper image.png` — change the on-screen wallpaper
- take screenshots, read what's on screen, open apps

## Hardening notes

- Full-disk encryption on the machine (LUKS) — non-negotiable for a box
  this accessible.
- Keep the machine updated; SSH is only as safe as the box it lands on.
- If you ever feel uneasy: `sudo userdel -r "$ASSISTANT"` removes the
  whole thing. The desktop setup keeps working without it.
