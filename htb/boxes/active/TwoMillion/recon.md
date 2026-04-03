# TwoMillion - Reconnaissance

## Target
- **IP:** 10.129.229.66
- **OS:** Linux (Ubuntu 22.04.2 LTS)
- **Difficulty:** Medium
- **Platform:** HackTheBox

## Nmap Scan
```
# Not yet performed - accessed via 2million.htb vhost
```

## Services
| Port | Service | Version | Notes |
|------|---------|---------|-------|
| 22   | SSH     | OpenSSH 8.9 | Valid user: admin |
| 80   | HTTP    | nginx   | Main application server |

## Initial Observations

The target is a web application at `2million.htb`. The landing page contains obfuscated JavaScript that reveals the application's API endpoints.

## Enumeration Process

### 1. JavaScript Deobfuscation

The page loads `inviteapi.min.js` which contains obfuscated code. After deobfuscation, two key functions were found:

```javascript
function verifyInviteCode(code) {
    $.ajax({
        type: "POST",
        dataType: "json",
        data: { "code": code },
        url: '/api/v1/invite/verify',
        success: function (response) { console.log(response); },
        error: function (response) { console.log(response); }
    });
}

function makeInviteCode() {
    $.ajax({
        type: "POST",
        dataType: "json",
        url: '/api/v1/invite/how/to/generate',
        success: function (response) { console.log(response); },
        error: function (response) { console.log(response); }
    });
}
```

### 2. Invite Code Generation

The endpoint `/api/v1/invite/how/to/generate` returns a ROT13-encrypted payload:

```json
{
  "0": 200,
  "success": 1,
  "data": {
    "data": "Va beqre gb trarengr gur vaivgr pbqr, znxr n CBFG erdhrfg gb \/ncv\/i1\/vaivgr\/trarengr",
    "enctype": "ROT13"
  },
  "hint": "Data is encrypted ... We should probbably check the encryption type in order to decrypt it..."
}
```

Decrypted (ROT13) and decoded (base64):
```
2BJNM-PFINL-AGCOU-A3E3A
```

### 3. User Registration

Using the invite code, a new user was registered:
- **Username:** testuser1
- **Email:** testuser1@email.com
- **Password:** password

### 4. API Enumeration (Authenticated)

After authentication, the API root reveals all available endpoints:

**User Endpoints (GET):**
| Endpoint | Description |
|----------|-------------|
| `/api/v1` | Route List |
| `/api/v1/invite/how/to/generate` | Instructions on invite code generation |
| `/api/v1/invite/generate` | Generate invite code |
| `/api/v1/invite/verify` | Verify invite code |
| `/api/v1/user/auth` | Check if user is authenticated |
| `/api/v1/user/vpn/generate` | Generate a new VPN configuration |
| `/api/v1/user/vpn/regenerate` | Regenerate VPN configuration |
| `/api/v1/user/vpn/download` | Download OVPN file |

**User Endpoints (POST):**
| Endpoint | Description |
|----------|-------------|
| `/api/v1/user/register` | Register a new user |
| `/api/v1/user/login` | Login with existing user |

**Admin Endpoints (GET):**
| Endpoint | Description |
|----------|-------------|
| `/api/v1/admin/auth` | Check if user is admin |

**Admin Endpoints (POST):**
| Endpoint | Description |
|----------|-------------|
| `/api/v1/admin/vpn/generate` | Generate VPN for specific user |

**Admin Endpoints (PUT):**
| Endpoint | Description |
|----------|-------------|
| `/api/v1/admin/settings/update` | Update user settings |

## Interesting Files/Directories

| Path | Description |
|------|-------------|
| `/api/v1/admin/settings/update` | IDOR vulnerability - can modify `is_admin` |
| `/api/v1/admin/vpn/generate` | Command injection via username parameter |
| `/var/www/html/.env` | Database credentials: `admin:SuperDuperPass123` |

## Credentials Discovered

| Service | Username | Password |
|---------|----------|----------|
| Database | admin | SuperDuperPass123 |
| SSH | admin | SuperDuperPass123 |

## Next Steps
- [x] Exploit IDOR to gain admin access
- [x] Exploit command injection in VPN generation
- [x] Obtain proper reverse shell
- [x] Enumerate for privilege escalation vectors
- [x] Obtain user.txt via admin SSH access
- [ ] Escalate to root

## Lessons Learned
1. ROT13 encoding is not security - it's obfuscation at best
2. Always enumerate all API endpoints, including admin routes
3. User-controlled input in administrative functions often leads to vulnerabilities
4. Database credentials in `.env` files are a common privilege escalation vector
5. Web app creds often reuse for SSH access
