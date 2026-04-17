# Password Attacks: Attacking Windows Credential Manager

**Module Path:** /academy/password-attacks
**Focus:** Attacking Windows Credential Manager
**Assessment:** No skills assessment detected in provided content.

---

## Section Progress

| Section | Topic | Status |
|---------|-------|--------|
| 1 | Windows Vault and Credential Manager | In Progress |
| 2 | (Pending) | Pending |

---

## Key Concepts

- **Credential Manager:** Built into Windows since Server 2008 R2 and Windows 7. Allows users/applications to securely store credentials for other systems and websites.
- **Storage Locations:**
  - `%UserProfile%\AppData\Local\Microsoft\Vault\`
  - `%UserProfile%\AppData\Local\Microsoft\Credentials\`
  - `%UserProfile%\AppData\Roaming\Microsoft\Vault\`
  - `%ProgramData%\Microsoft\Vault\`
  - `%SystemRoot%\System32\config\systemprofile\AppData\Roaming\Microsoft\Vault\`
- **Encryption:** Credentials encrypted with AES-128/AES-256, keys stored in `Policy.vpol` file, protected by DPAPI.
- **Credential Guard:** Further protects DPAPI master keys in secured memory enclaves via Virtualization-based Security (VBS).

---

## Credential Types

| Type | Description |
|------|-------------|
| Web Credentials | Associated with websites and online accounts. |
| Generic Credentials | Generic authentication data for internal Windows resources and applications. |

---

## Tools Introduced

- **Mimikatz:** For extracting credentials from Windows Credential Manager via DPAPI.
- **LaZagne:** For credential dumping from various password stores.
- **SharpWeb:** .NET tool for browser credential retrieval.
- **Rubeus / Kekeo:** For Kerberos-based credential attacks.

---

## Vault / Credential Manager Notes

- Vault folders contain `Policy.vpol` which holds AES keys protected by DPAPI.
- Credentials are organized in encrypted folders under user profiles.
- Credential Guard isolates DPAPI master keys in memory enclaves.

---

## Gaps / Follow-up

- How does Credential Guard affect mimikatz's ability to extract DPAPI keys?
- What is the difference between `CredEnumerate` API and direct file system access?
- What are the practical attack vectors when Credential Guard is enabled vs. disabled?