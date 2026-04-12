# Skills Assessment: Footprinting Lab - Medium

## Target
- **IP / URL:** `10.129.202.41`
- **OS:** Windows 10 / Server 2019 Build 17763
- **Hostname:** `WINMEDIUM`
- **Difficulty:** Medium
- **Client:** Inlanefreight Ltd
- **Scope:** Shared internal server accessible by all employees — no aggressive exploits

## Context
- **Goal:** Gather as much information as possible and find ways to use it against the server itself
- **Proof of compromise:** Obtain credentials for user **`HTB`**
- **Rules:** Passive enumeration only — no exploit attacks

---

## Recon

### Nmap Scan
See [raw_data/nmap.initial](raw_data/nmap.initial) for full output.

| Port | Service | Notes |
|------|---------|-------|
| 111 | rpcbind | Maps to NFS services |
| 135 | MSRPC | Windows RPC |
| 139/445 | SMB | File sharing; required auth for share listing |
| 2049 | NFS | `nlockmgr` / `mountd` |
| 3389 | RDP | Confirmed access path |
| 5985 | WinRM | Available but alex not authorized |

### RPC Enumeration
Null session and authenticated `rpcclient` enumeration were blocked:
- `NT_STATUS_ACCESS_DENIED` (null session)
- `NT_STATUS_LOGON_FAILURE` / `NT_STATUS_CONNECTION_DISCONNECTED` (authenticated)

---

## Exploitation Path

### Step 1: NFS Enumeration
```bash
showmount -e 10.129.202.41
sudo mount -t nfs 10.129.202.41:/TechSupport /mnt/nfs_check
```

**Result:** Export `/TechSupport` is world-mountable. Contains 138 ticket files, only one non-empty.

**Key finding:** `ticket4238791283782.txt` contained credentials:
```
alex.g@web.dev.inlanefreight.htb:lol123!mD
```

### Step 2: Credential Testing
Tested multiple service + username format combinations:

| Format | SMB | WinRM | RDP |
|--------|-----|-------|-----|
| `alex.g@web.dev.inlanefreight.htb` | `STATUS_LOGON_FAILURE` | Failed | Failed |
| `alex.g` | `STATUS_LOGON_FAILURE` | Failed | Failed |
| **`alex`** | **Authenticated** | Failed | **Success** |

**Lesson:** Username format matters on Windows. The leaked email UPN (`alex.g`) required shortening to the SAM account name (`alex`).

### Step 3: SMB Enumeration (as alex)
```bash
smbmap -H 10.129.202.41 -u 'alex' -p 'lol123!mD'
```

| Share | Permissions |
|-------|-------------|
| ADMIN$ | NO ACCESS |
| C$ | NO ACCESS |
| **devshare** | **READ, WRITE** |
| IPC$ | READ ONLY |
| Users | READ ONLY |

Inside `devshare`, found `important.txt` (16 bytes). Contents:
```
sa:87N1ns@slls83
```

### Step 4: RDP + SQL Server Enumeration
- Tunneld RDP via SSH (`-L 13389:10.129.202.41:3389`)
- Logged in as `alex:lol123!mD`
- Found SQL Server Management Studio (SSMS) on the desktop
- Connected to local SQL Server instance as `sa:87N1ns@slls83` (sysadmin)

### Step 5: Query the Database
```sql
USE accounts;
SELECT [id], [name], [password]
FROM [dbo].[devsacc]
WHERE [name] = 'HTB';
```

**Result:**

| id | name | password |
|----|------|----------|
| 157 | HTB | `lnch7ehrdn437AoqVPK4zWR` |

---

## Credentials

| User | Password |
|------|----------|
| **HTB** | `lnch7ehrdn437AoqVPK4zWR` |

### Supporting Credentials Found
| Account | Password | Source |
|---------|----------|--------|
| `alex` | `lol123!mD` | NFS `/TechSupport/ticket4238791283782.txt` |
| `sa` (SQL Server) | `87N1ns@slls83` | SMB `devshare/important.txt` |

---

## Lessons

1. **NFS exports are frequently overlooked** — an unsecured `/TechSupport` share exposed internal support tickets containing valid domain credentials.
2. **Username format matters on Windows** — the leaked email `alex.g@...` only worked as the short SAM name `alex`.
3. **Credential chaining is powerful** — one leaked ticket opened SMB, which revealed a second credential, which unlocked the SQL Server database.
4. **Shared internal servers concentrate risk** — multiple services (NFS, SMB, RDP, SQL) on a single host multiply exposure when any one service leaks data.
5. **No exploits required** — the entire compromise was achieved through methodical enumeration, credential recovery, and reuse.
