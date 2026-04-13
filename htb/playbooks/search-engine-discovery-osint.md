# Search Engine Discovery / OSINT

Search engines index a vast portion of the web — security professionals can use them to uncover employee info, sensitive documents, hidden login pages, and exposed credentials through specialized search operators.

## Why It Matters

| Benefit | Description |
|---------|-------------|
| **Open Source** | Publicly accessible — legal and ethical |
| **Breadth** | Massive indexed coverage across many sources |
| **Ease of Use** | No specialized technical skills required |
| **Cost-Effective** | Free, readily available |

## Use Cases

- **Security Assessment** — identify vulnerabilities, exposed data, attack vectors
- **Competitive Intelligence** — competitors' products, services, strategies
- **Investigative Journalism** — hidden connections, financial transactions
- **Threat Intelligence** — emerging threats, tracking malicious actors

---

## Search Operators Reference

| Operator | Description | Example |
|----------|-------------|---------|
| `site:` | Limits results to a specific domain | `site:example.com` |
| `inurl:` | Pages with term in URL | `inurl:login` |
| `filetype:` | Search for file types | `filetype:pdf` |
| `intitle:` | Pages with term in title | `intitle:"confidential report"` |
| `intext:` / `inbody:` | Term in body text | `intext:"password reset"` |
| `cache:` | Cached version of a page | `cache:example.com` |
| `link:` | Pages linking to a URL | `link:example.com` |
| `related:` | Sites related to a URL | `related:example.com` |
| `info:` | Summary info about a page | `info:example.com` |
| `define:` | Definitions of words/phrases | `define:phishing` |
| `numrange:` | Numbers within a range | `site:example.com numrange:1000-2000` |
| `allintext:` | All words in body text | `allintext:admin password reset` |
| `allinurl:` | All words in URL | `allinurl:admin panel` |
| `allintitle:` | All words in title | `allintitle:confidential report 2023` |
| `AND` | All terms must be present | `site:example.com AND inurl:admin` |
| `OR` | Any term matches | `"linux" OR "ubuntu" OR "debian"` |
| `NOT` | Excludes term | `site:bank.com NOT inurl:login` |
| `*` (wildcard) | Any character/word | `site:socialnetwork.com filetype:pdf user* manual` |
| `..` (range) | Numerical range | `site:ecommerce.com "price" 100..500` |
| `" "` | Exact phrase | `"information security policy"` |
| `-` | Excludes term | `site:news.com -inurl:sports` |

---

## Google Dorking (Google Hacking)

Leverages search operators to uncover sensitive info, vulnerabilities, or hidden content.

### Common Dorks

**Finding Login Pages:**
```
site:example.com inurl:login
site:example.com (inurl:login OR inurl:admin)
```

**Identifying Exposed Files:**
```
site:example.com filetype:pdf
site:example.com (filetype:xls OR filetype:docx)
```

**Uncovering Configuration Files:**
```
site:example.com inurl:config.php
site:example.com (ext:conf OR ext:cnf)
```

**Locating Database Backups:**
```
site:example.com inurl:backup
site:example.com filetype:sql
```

### Resources

- [Google Hacking Database (Exploit-DB)](https://www.exploit-db.com/google-hacking-database)

---

## Key Limitations

- Search engines do not index all information
- Some data may be deliberately hidden or protected
- Results depend on what has been indexed
