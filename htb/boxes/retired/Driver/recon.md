# Driver — Reconnaissance

**Target IP:** 10.129.95.238 | **Hostname:** DRIVER | **OS:** Windows 7–10 (WORKGROUP)
**Updated:** 2026-03-24

---

## Nmap Scan

```
PORT     STATE SERVICE      VERSION
80/tcp   open  http         Microsoft IIS httpd 10.0
445/tcp  open  microsoft-ds Microsoft Windows 7 - 10 microsoft-ds (workgroup: WORKGROUP)
135/tcp  open  msrpc        Microsoft Windows RPC
5985/tcp open  http         Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP)
```

---

## Services

| Port | Service | Notes |
|------|---------|-------|
| 80   | HTTP    | **401 Unauthorized** — Basic realm: `MFP Firmware Update Center` |
| 135  | MSRPC   | Standard Windows RPC |
| 445  | SMB     | **Guest/null auth denied** — SMB signing disabled |
| 5985 | WinRM   | Remote management port — reachable with credentials |

---

## HTTP (Port 80) — MFP Firmware Update Center

### Authentication
- HTTP Basic Auth — **Credentials: `admin:admin`**
- Realm: `MFP Firmware Update Center`

### Discovered Pages

| Status | Path | Notes |
|--------|------|-------|
| 200 | `/index.php` | Home page |
| 200 | `/fw_up.php` | **Firmware upload** — primary attack surface |
| 200 | `/images/ricoh.png` | Printer image accessible directly |

### Firmware Upload (`/fw_up.php`)
- Accepts **all file extensions**: `.bin`, `.dll`, `.exe`, `.cab`, `.zip`, `.scf`
- Success response: `http://driver.htb/fw_up.php?msg=SUCCESS`
- Uploaded files not directly web-accessible

---

## SMB (Port 445)

- **Guest access denied** — tested with `guest`, `anonymous`, null
- SMB signing **disabled** (dangerous/default)
- **Firewall allows 445 from 10.0.0.0/8** → Responder relay viable

### SMB Enum (all failed)
```bash
smbclient -L //10.129.95.238 -N        # → NT_STATUS_ACCESS_DENIED
smbclient -L //10.129.95.238 -U guest  # → NT_STATUS_LOGON_FAILURE
```

---

## Key Observations

- **Hostname "DRIVER"** + MFP portal = print-driver-themed target
- Firmware upload accepts arbitrary extensions → **SCF upload possible**
- SMB guest blocked, but 445 accessible from VPN range → **NTLM capture via SCF**
- WinRM (5985) open → `evil-winrm` ready once credentials cracked
