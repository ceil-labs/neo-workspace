# Certified — Privilege Escalation

## Current Status
- [x] User flag captured: `4c827f9708a774df0e26ba85de7f03dc`
- [ ] Root flag: **Pending**

## Current Context
- **Shell:** WinRM as `management_svc` (NT hash: `a091c1832bcdd4677c28b5a6a1295584`)
- **Groups:** Management, Remote Management Users
- **Domain:** certified.htb (Domain Controller: DC01)

---

## Enumeration (Pending)

### BloodHound Analysis
From BloodHound data collected (`raw_data/certified_bloodhound.zip`):
- `management_svc` is a service account in the `Management` group
- The path from `Management` group to Domain Admin has not yet been fully mapped
- The task description indicates **ADCS ESC9** is the intended root escalation path

### Next Step: ADCS ESC9 (Enterprise CA ESC9)

**ESC9** is a vulnerable certificate template configuration in Active Directory Certificate Services (ADCS). The attack leverages:

1. A certificate template that has **EDITF_ATTRIBUTESUBJECTALTNAME2** set (allowing arbitrary SAN specification)
2. The template uses a ** Kerberos authentication** issuance requirement
3. A user account can enroll in the template

**Attack path:**
1. Find the vulnerable CA and template: `Certify.exe find /vulnerable`
2. Request a certificate for the DC (or Administrator) using management_svc's TGT
3. Use the certificate to authenticate as the target user

### Actions to Try

```cmd
# From WinRM shell, enumerate ADCS
certify.exe find /vulnerable
```

Or via PKINITtools session:
```bash
# Using the management_svc ccache from earlier
export KRB5CCNAME=TGT_ccache
python3 Certify/request.py certify.htb/management_svc -pfx-pass Vo0bUFIlwobW0dnHEWVq -dc-ip 10.129.231.186
```

### Key Requirements for ESC9
- Access to a CA that has a template with EDITF_ATTRIBUTESUBJECTALTNAME2
- Enrollment rights on that template
- Target is a user/computer with UPN that resolves to a valid account

---

## Credentials Summary

| Account | Type | NT Hash | Use |
|---------|------|---------|-----|
| judith.mader | User | N/A | judith09 (password) — initial access |
| management_svc | Service | a091c1832bcdd4677c28b5a6a1295584 | User shell, Shadow Credential target |

## Flags

| Flag | Location | Value |
|------|----------|-------|
| User | `C:\Users\management_svc\Desktop\user.txt` | `4c827f9708a774df0e26ba85de7f03dc` |
| Root | `C:\Users\Administrator\Desktop\root.txt` | **Pending** |

## Lessons (So Far)
1. **management_svc is a stepping stone** — not the final target; the actual escalation requires ADCS exploitation
2. **ESC9 requires certificate enrollment** — check if management_svc can enroll in any certificate templates that permit SAN specification
3. **PKINITtools + ESC9 = Kerberos authentication via certificate** — a powerful alternative to password-based authentication
