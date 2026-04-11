# Skills Assessment: Footprinting Lab - Easy

## Target
- **IP / URL:** `10.129.60.155`
- **OS:** Ubuntu Linux
- **Difficulty:** Easy
- **Client:** Inlanefreight Ltd
- **Scope:** Internal DNS server — NO aggressive exploits

## Context
- **Credentials found:** `ceil:qwer1234`
- **Clue:** SSH keys mentioned on forum
- **Goal:** Enumerate server, find `flag.txt`
- **Rules:** Passive enumeration only — no exploit attacks

---

## Recon

### Nmap Scan

```bash
sudo nmap -sC -sV -Pn 10.129.60.155 -oN raw_data/nmap.initial
```

```
PORT     STATE SERVICE VERSION
21/tcp   open  ftp     ProFTPD Server (ftp.int.inlanefreight.htb)
22/tcp   open  ssh     OpenSSH 8.2p1 Ubuntu 4ubuntu0.2
53/tcp   open  domain  ISC BIND 9.16.1 (Ubuntu Linux)
2121/tcp open  ftp     ProFTPD Server (Ceil's FTP)
```

**Key Findings:**
- Two FTP services running on ports `21` and `2121`
- Port 21 banner reveals internal hostname: `ftp.int.inlanefreight.htb`
- Port 2121 banner reveals user context: `Ceil's FTP`
- SSH available on port 22
- DNS (BIND 9.16.1) on port 53

### Port 21 (Inlanefreight FTP)

Logged in with provided credentials `ceil:qwer1234`. Root-owned, empty directory — no useful files here.

### Port 2121 (Ceil's FTP)

Logged in with same credentials. This is Ceil's actual home directory. Found `.ssh/` directory containing SSH keys:

```bash
ftp> ls -lah .ssh
-rw-rw-r-- 1 ceil ceil 738  id_rsa.pub
-rw------- 1 ceil ceil 3381 id_rsa
-rw-rw-r-- 1 ceil ceil 738  authorized_keys
```

Downloaded keys locally:
```bash
ftp> get id_rsa
ftp> get id_rsa.pub
```

---

## Exploitation

### Initial Access

Used the recovered SSH private key to authenticate as `ceil` via SSH:

```bash
chmod 600 id_rsa
ssh -i id_rsa ceil@10.129.60.155
```

Successful login as `ceil`. Hostname: `NIXEASY`.

### Privilege Escalation

None required. The `flag.txt` was readable from `/home/flag/flag.txt` as user `ceil`.

---

## Flags

| Level      | Flag                                                   |
|------------|--------------------------------------------------------|
| `flag.txt` | `HTB{7nrzise7hednrxihskjed7nzrgkweunj47zngrhdbkjhgdfbjkc7hgj}` |

---

## Lessons

1. **Enumeration depth matters.** Two FTP services on different ports served completely different purposes — one was a system service with an empty root-owned directory, the other was a user's personal FTP exposing sensitive files.
2. **SSH key exposure is critical.** Finding `id_rsa` in an accessible FTP share allowed direct, passwordless authentication to the target.
3. **Credential reuse + information leakage.** The provided credentials (`ceil:qwer1234`) gave access to both FTP services. The banner on port 2121 (`Ceil's FTP`) was a clear indicator to investigate that service more closely.
4. **No exploits needed.** This assessment was purely about thorough service enumeration and understanding how exposed data (SSH keys) can be leveraged for unauthorized access.
