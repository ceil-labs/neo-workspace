# AD Time Synchronization Playbook

Active Directory (AD) attacks require precise time synchronization with the target Domain Controller (DC). Kerberos authentication is particularly sensitive to clock skew.

## Why Time Sync Matters

- **Kerberos**: Allows maximum 5 minutes clock skew by default
- **KRB_AP_ERR_SKEW**: Error when local time differs too much from DC
- **Shadow Credentials**: PKINIT requires time alignment
- **Kerberoasting**: Ticket requests fail with clock skew errors

## Quick Commands

### Option 1: Sync with Target DC (Fastest)
```bash
# Sync local time with target DC
sudo net time set -S <DC_IP>

# Example:
sudo net time set -S 10.129.231.186
```

### Option 2: Manual Time Setting
```bash
# Disable NTP first
sudo timedatectl set-ntp false

# Set time manually (use DC time from nmap/recon)
sudo timedatectl set-time '2026-04-05 17:40:00'

# Re-enable NTP after attack
sudo timedatectl set-ntp true
```

### Option 3: Set Timezone + NTP
```bash
# Set correct timezone (e.g., Asia/Manila)
sudo timedatectl set-timezone Asia/Manila

# Enable NTP sync
sudo timedatectl set-ntp true
```

## Verification

```bash
# Check current time
date
timedatectl

# Compare with DC time
nmap -sV -p88 --script krb5-enum-users <DC_IP> 2>/dev/null | grep -i time
```

## After Attack: Revert Time (Asia/Manila)

```bash
# Set back to your timezone (Asia/Manila)
sudo timedatectl set-timezone Asia/Manila

# Re-enable NTP to sync back to real time
sudo timedatectl set-ntp true

# Verify correct time
date
```

**Note:** Asia/Manila is the operator's home timezone. Always revert after attacking to maintain accurate local logs and timestamps.

## Common Errors Fixed

| Error | Cause | Fix |
|-------|-------|-----|
| `KRB_AP_ERR_SKEW` | Clock skew too great | `sudo net time set -S <DC_IP>` |
| `Clock skew too great` | Time difference > 5 min | Sync time with DC |
| Kerberoast fails | Time misalignment | Run time sync before attack |
| PKINIT fails | Certificate auth requires sync | `sudo net time set -S <DC_IP>` |

## Tools Affected

- impacket-GetUserSPNs
- certipy-ad
- pywhisker / PKINITtools
- gettgtpkinit.py
- bloodhound-python
- Any Kerberos-based authentication

## Notes

- Always sync time **before** Kerberos operations
- `net time set -S` requires `smbclient`/`net` tools
- Some tools work with `-k` (Kerberos) flag to bypass password auth
- Remember to revert time after attacking (for accurate logs)
