# Password Attacks: Attacking Windows Credential Manager

**Module Path:** HTB Academy / Password Attacks / Attacking Windows Credential Manager  
**Assessment:** Yes  
**Date Started:** 2026-04-17

---

## Sections

| # | Section | Status | Notes |
|---|---------|--------|-------|
| 1 | Windows Vault and Credential Manager | ⬜ | Vault locations, DPAPI, Credential Guard |
| 2 | Credential Dumping Techniques | ⬜ | Mimikatz, SharpDPAPI, etc. |
| 3 | Credential Decryption | ⬜ | Master keys, AES decryption |
| 4 | Skills Assessment | ⬜ | Practical exploitation |

---

## Key Concepts

### Windows Credential Storage Locations
- `%UserProfile%\AppData\Local\Microsoft\Vault\`
- `%UserProfile%\AppData\Local\Microsoft\Credentials\`
- `%UserProfile%\AppData\Roaming\Microsoft\Vault\`
- `%ProgramData%\Microsoft\Vault\`
- `%SystemRoot%\System32\config\systemprofile\AppData\Roaming\Microsoft\Vault\`

### Credential Types
| Name | Description |
|------|-------------|
| **Web Credentials** | Credentials associated with websites and online accounts |
| **Windows Credentials** | Credentials for network resources, RDP, etc. |

### DPAPI (Data Protection API)
- Protects credential vaults with AES-128 or AES-256
- Keys stored in `Policy.vpol` files
- Protected by user's password/system key

### Credential Guard
- Virtualization-based Security (VBS)
- Protects DPAPI master keys in isolated memory enclaves
- Makes credential extraction more difficult

---

## Tools Introduced

| Tool | Purpose |
|------|---------|
| `mimikatz` | Credential extraction and DPAPI manipulation |
| `SharpDPAPI` | C# DPAPI credential extraction |
| `vaultcmd` | Built-in Windows vault management |
| `rundll32 keymgr.dll,KRShowKeyMgr` | GUI credential manager |

---

## Gaps / Follow-up

- [ ] Practice with mimikatz dpapi commands
- [ ] Understand Credential Guard bypass techniques
- [ ] Learn to identify when Credential Guard is active
