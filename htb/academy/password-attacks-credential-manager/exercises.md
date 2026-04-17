# Exercises — Attacking Windows Credential Manager

---

## Section: Windows Vault and Credential Manager

### Exercise 1
**Question:** What are the five locations where Windows stores credential vaults?  
**Answer:**  
1. `%UserProfile%\AppData\Local\Microsoft\Vault\`
2. `%UserProfile%\AppData\Local\Microsoft\Credentials\`
3. `%UserProfile%\AppData\Roaming\Microsoft\Vault\`
4. `%ProgramData%\Microsoft\Vault\`
5. `%SystemRoot%\System32\config\systemprofile\AppData\Roaming\Microsoft\Vault\`

**Explanation:** Windows stores credentials in encrypted vault folders under user profiles and system directories. The exact locations vary by Windows version and credential type.

---

### Exercise 2
**Question:** What file contains the AES encryption keys for credential vaults?  
**Answer:** `Policy.vpol`

**Explanation:** Each vault folder contains a `Policy.vpol` file with AES-128 or AES-256 keys protected by DPAPI.

---

### Exercise 3
**Question:** What Windows feature protects DPAPI master keys using virtualization-based security?  
**Answer:** Credential Guard

**Explanation:** Credential Guard uses VBS (Virtualization-based Security) to isolate DPAPI master keys in secured memory enclaves, making extraction significantly more difficult.

---

## Section: Credential Dumping Techniques

### Exercise 1
**Question:** What built-in Windows command can display stored credentials in a GUI?  
**Answer:** `rundll32 keymgr.dll,KRShowKeyMgr` OR `cmdkey /list` for CLI

**Explanation:** `rundll32 keymgr.dll,KRShowKeyMgr` invokes the legacy Stored User Names and Passwords GUI. `cmdkey /list` does the same from command line without GUI.

---

### Exercise 2
**Question:** Which mimikatz module handles DPAPI credential extraction?  
**Answer:** `dpapi::` module (e.g., `dpapi::cred`, `dpapi::vault`) and `sekurlsa::credman`

**Explanation:** 
- `dpapi::cred` / `dpapi::vault` — manual decryption of vault files
- `sekurlsa::credman` — dumps Credential Manager entries directly from LSASS memory (faster, no file parsing needed)

---

### Exercise 3 (from assessment)
**Question:** What two credentials were extracted in the assessment?  
**Answer:**
1. `SRV01\mcharles` — logon password: `proofs1insight1rustles!`
2. `mcharles@inlanefreight.local` — OneDrive: `Inlanefreight#2025`

**Explanation:** Both extracted via `sekurlsa::credman` from LSASS memory. The logon credential was also visible via `cmdkey /list`.

---

## Section: Credential Decryption

### Exercise 1
**Question:** What is required to decrypt DPAPI-protected credentials?  
**Answer:** The user's master key (derived from password) or access to LSASS memory

**Explanation:** DPAPI uses master keys derived from user credentials or system-specific backup keys. Without these, decryption is computationally infeasible. However, `sekurlsa::credman` bypasses decryption entirely by extracting plaintext from LSASS.

---

### Exercise 2
**Question:** What tool can extract credentials without mimikatz (C# alternative)?  
**Answer:** SharpDPAPI

**Explanation:** SharpDPAPI is a C# port of DPAPI functionality that can extract and decrypt credentials without requiring mimikatz.

---

## Section: Lateral Movement with Stored Credentials

### Exercise 1
**Question:** How do you reuse a stored credential without knowing the password?  
**Answer:** `runas /savecred /user:DOMAIN\user command`

**Explanation:** The `/savecred` flag tells runas to use a credential previously stored via Credential Manager. No password prompt — fully transparent lateral movement.

---

### Exercise 2
**Question:** Why did the msconfig UAC bypass work when launched as mcharles but not as sadams?  
**Answer:** UAC behavior depends on the user context — mcharles had admin rights and the launch was silent; sadams triggering msconfig caused a UAC prompt because the credential wasn't cached for elevation.

**Explanation:** When msconfig is launched from a user context that is a member of Administrators group, the Tools → Command Prompt launch spawns cmd.exe at high integrity WITHOUT prompting. This is a known UAC bypass technique (SILENTBYPASS).