# Administrator — Privilege Escalation

> **Status:** ✅ COMPLETE — Domain Admin achieved via DCSync + Pass-the-Hash.

Full attack path documented in `exploit.md`. This file covers the critical escalation techniques.

---

## Escalation: Ethan → Domain Admin

### DCSync — The Crown Jewel

Ethan has two extended rights on the domain:
- `DS-Replication-Get-Changes` (`1133f6aa-9e97-4538-9da2-0889b8a28c38`)
- `DS-Replication-Get-Changes-All` (`1131f6aa-9e97-4538-9da2-0889b8a28c38`)

Together these = **DCSync**. Ethan can impersonate a Domain Controller and pull **all password hashes** from NTDS.DIT — over the network, no local access needed.

```bash
impacket-secretsdump administrator.htb/ethan:limpbizkit@10.129.213.179
```

Output includes every NT hash + Kerberos keys (AES256/AES128/DES) for all accounts.

### Pass-the-Hash — Administrator Shell

With the Administrator NT hash, no plaintext needed:

```bash
evil-winrm -i 10.129.213.179 -u administrator -H 3dc553ce4b9fd20bd016e098d2d2fd2e
```

→ **NT AUTHORITY\SYSTEM** on the DC.

---

## Key Concepts

### DCSync
- Mimics AD replication traffic (DRSUAPI/MS-DRSR) — same protocol DCs use to sync with each other
- Detection: Event ID `4662` on DC (often unmonitored)
- Impacket-secretsdump handles the entire protocol over the network

### Pass-the-Hash (PTH)
Windows NTLM auth verifies the hash, not the password. Tools like `evil-winrm`, `netexec`, `mimikatz` all support `-H <nthash>`.

### Golden Ticket (Persistence)
The `krbtgt` NT hash enables forging TGTs valid for years:
```bash
impacket-goldenPac administrator.htb/ethan@DC.administrator.htb -nthash 1181ba47d45fa2c76385a82409cbfaf6
```

---

## Lessons

1. **DCSync = Domain Admin.** Any user with `GetChanges` + `GetChanges-All` IS a DA-equivalent. BloodHound flags this explicitly — always check.
2. **ACL chains are reliable attack paths.** No server-side exploits needed — just misconfigured permissions chained together.
3. **Kerberos keys == domain persistence.** AES/DES keys from secretsdump enable golden tickets that are quieter than NTLM PTH.
4. **`net user /domain` fails even with ForceChangePassword** — use `rpcclient setuserinfo2` instead.
5. **`impacket-secretsdump` works remotely** — no foothold on the DC required.

## Flags
| Flag | Location | Value |
|------|----------|-------|
| user.txt | Emily's Desktop | `3ff853d4941be6f97bb9ca31e41d813c` |
| root.txt | Administrator's Desktop | (captured) |
