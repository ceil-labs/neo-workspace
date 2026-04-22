# Skills Assessment

## Context
> We were commissioned by the company **Inlanefreight** to conduct a penetration test against three different hosts to check the servers' configuration and security. We were informed that a flag had been placed somewhere on each server to prove successful access. These flags have the following format: **HTB{...}**

## Targets (3 Hosts)

### Server 1 — Email, Customers & Files
- **Role:** Email server, customer management, file management
- **IP / URL:** *(TBD — lab environment)*
- **OS:** *(TBD)*
- **Difficulty:** Easy

### Server 2
- **IP / URL:** *(TBD)*
- **OS:** *(TBD)*
- **Difficulty:** Easy

### Server 3
- **IP / URL:** *(TBD)*
- **OS:** *(TBD)*
- **Difficulty:** Easy

## Recon

### Nmap Scan Results
```
PORT     STATE SERVICE       VERSION
21/tcp   open  ftp           Core FTP Server
25/tcp   open  smtp          hMailServer smtpd (AUTH LOGIN PLAIN)
80/tcp   open  http          Apache/2.4.53 (XAMPP)
443/tcp  open  https         Apache/2.4.53 (Basic Auth)
587/tcp  open  smtp          hMailServer smtpd (AUTH LOGIN PLAIN)
3306/tcp open  mysql         MariaDB 5.5.5-10.4.24
3389/tcp open  ms-wbt-server Microsoft Terminal Services (RDP)
```

### Service Enum
- **SMTP (25/587):** hMailServer, AUTH LOGIN PLAIN enabled
- **FTP (21):** Core FTP Server, TLS enabled, no anonymous access
- **HTTP (80):** XAMPP welcome page
- **HTTPS (443):** HTTP Basic Authentication required
- **MySQL (3306):** MariaDB — potential hMailServer backend
- **RDP (3389):** Windows Terminal Services


## Exploitation
### Initial Access — Server 1
```bash
# commands, payloads
```

### Server 2
```bash
# commands, payloads
```

### Server 3
```bash
# commands, payloads
```

## Flags
| Server | Host | Flag | Status |
|--------|------|------|--------|
| 1 | Email/Files | HTB{...} | ⏳ Pending |
| 2 | TBD | HTB{...} | ⏳ Pending |
| 3 | TBD | HTB{...} | ⏳ Pending |

## Lessons
