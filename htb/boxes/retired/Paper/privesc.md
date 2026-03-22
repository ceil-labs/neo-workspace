# Paper — Privilege Escalation Roadmap

> **Box:** Paper | **Target:** 10.129.136.31 | **Date:** 2026-03-22
> **Status:** ✅ **ROOTED** | **user.txt:** `f10419a09348ecd49a3545d5b12661f7`
> **root.txt:** `e50eb2bb38c864627c54b8c0d9f0802f`

---

## ✅ Final Status — ROOT ACHIEVED

| Field | Value |
|-------|-------|
| **Shell** | `dwight` (via SSH) |
| **Password** | `Queenofblad3s!23` |
| **user.txt** | ✅ `f10419a09348ecd49a3545d5b12661f7` |
| **Shell #2** | `hacked` (created via CVE-2021-3560) |
| **hacked pass** | `password` |
| **root access** | ✅ **ACHIEVED** via `sudo -i` as hacked user |
| **root.txt** | ✅ `e50eb2bb38c864627c54b8c0d9f0802f` |

---

## 🏆 Root Method — CVE-2021-3560 (polkit D-Bus Race Condition)

**Exploit:** `50011.sh` (exploit-db)
**Status:** ✅ **SUCCESSFUL**

### What Worked

The manual D-Bus timing approach had a "ghost user" issue — the user was created but not synced to `/etc/passwd`. However, the `50011.sh` script from exploit-db executed reliably and produced a fully functional privileged user.

### Exploit-db Reference

| Field | Value |
|-------|-------|
| **EDB-ID** | 50011 |
| **CVE** | CVE-2021-3560 |
| **File** | `50011.sh` (in box directory) |

### Running the Exploit

```bash
# Make executable and run
chmod +x 50011.sh
./50011.sh

# Expected output: Creates user "hacker" (or configurable username)
# User is added to sudo group
# Login and escalate:
su - hacker
# Password: password
sudo -i
# Password: password
# → ROOT shell
```

### Why Manual Approach Failed

The manual D-Bus timing approach created the user but with an incomplete sync to `/etc/passwd`. The race condition timing was slightly off, resulting in a "ghost user" visible to `id` but not to sudo's NSS lookup.

**Key insight:** The `50011.sh` script handles timing more robustly and ensures complete user creation with proper `/etc/passwd` and `/etc/shadow` entries.

### Final Privesc Chain

```
dwight@paper:~$ ./50011.sh
    ↓
User "hacker" created (uid=1005, gid=1005, groups=hacker,sudo)
    ↓
su - hacker
Password: password
    ↓
hacker@paper:~$ sudo -i
Password: password
    ↓
root@paper:~# cat /root/root.txt
e50eb2bb38c864627c54b8c0d9f0802f
```

---

## 📊 Privesc Progress Log — FINAL

| Date | Action | Result |
|------|--------|--------|
| 2026-03-21 | SSH as dwight | ✅ Connected |
| 2026-03-21 | user.txt captured | ✅ f10419a09348ecd49a3545d5b12661f7 |
| 2026-03-21 | CVE-2021-3560 manual approach | ✅ User created, ❌ sudo blocked (ghost user) |
| 2026-03-22 | **50011.sh exploit** | **✅ SUCCESSFUL — ROOT SHELL** |
| 2026-03-22 | **root.txt captured** | **✅ e50eb2bb38c864627c54b8c0d9f0802f** |

---

## 🎓 Lessons Learned

1. **Ghost user problem with CVE-2021-3560:** The D-Bus race condition timing is critical. If slightly off, the user is created in accounts-daemon but never synced to `/etc/passwd`, making sudo fail. The exploit-db script (50011.sh) handles this more robustly.

2. **Pre-built exploits > manual reconstruction:** When an exploit-db script exists, use it. Manual D-Bus commands are educational but less reliable than proven implementations.

3. **polkit CVE-2021-3560 is the canonical privesc for Paper:** No password reuse, no kernel exploits needed. The polkit vulnerability is the intended path.

4. **Iterate on failed approaches:** The first CVE-2021-3560 attempt "failed" (ghost user) but the technique was correct. Finding the working implementation (50011.sh) resolved the issue.

---

*Privesc roadmap completed: 2026-03-22 — ROOT SHELL OBTAINED via CVE-2021-3560 (50011.sh)*
